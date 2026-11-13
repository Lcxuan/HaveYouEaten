#!/usr/bin/env python3
"""一次性导入 HowToCook 菜谱，生成 docs/recipes.sql 并复制封面到 public/images/recipes。

用法：
    python docs/import_howtocook.py --repo /tmp/howtocook \
        --out docs/recipes.sql \
        --image-dir public/images/recipes \
        --image-base http://localhost:8080/images/recipes
"""

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path

CATEGORY_WHITELIST = {
    "meat_dish",
    "vegetable_dish",
    "soup",
    "aquatic",
    "breakfast",
    "staple",
}

IMAGE_EXTS = {".jpg", ".jpeg", ".png", ".webp"}

TOOL_SUFFIXES = (
    "锅", "刀", "砧板", "烤箱", "微波炉", "电饭煲", "破壁机", "料理机",
    "漏勺", "锅铲", "筷子", "碗", "盘", "保鲜膜", "锡纸", "厨房纸",
    "温度计", "电子秤", "勺子", "铲子",
)

TOOL_KEYWORDS = (
    "炒锅", "平底锅", "汤锅", "蒸锅", "高压锅", "不粘锅", "锅一个",
    "烤箱", "微波炉", "电饭煲", "破壁机", "料理机", "砧板", "菜刀",
    "锅铲", "漏勺", "保鲜膜", "锡纸", "厨房纸", "温度计", "电子秤",
)

IMAGE_MD_RE = re.compile(r"!\[[^\]]*\]\([^)]*\)")
IMAGE_HTML_RE = re.compile(r"<img[^>]*>", re.IGNORECASE)
LIST_RE = re.compile(r"^\s*(?:\d+[.、)]|[-*+])\s+(.*)$")
NUMBERED_RE = re.compile(r"^\s*\d+[.、)]\s+(.*)$")
STAR_RE = re.compile(r"预估烹饪难度[：:]\s*(★+)")
HOUR_RE = re.compile(r"(\d+(?:\.\d+)?)\s*小时")
MINUTE_RE = re.compile(r"(\d+)\s*分钟")
AMOUNT_RE = re.compile(r"^(.+?)\s*[：:]\s*(.+)$")
AMOUNT_SPACE_RE = re.compile(r"^(.+?)\s+((?:\d|半|一|两|几).*)$")


def run_git(repo: Path, *args: str) -> bytes:
    return subprocess.run(
        ["git", "-C", str(repo), *args],
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
    ).stdout


def list_recipe_files(repo: Path) -> list[str]:
    if (repo / ".git").exists():
        output = run_git(repo, "ls-tree", "-r", "--name-only", "HEAD", "--", "dishes")
        files = output.decode("utf-8").splitlines()
    else:
        files = [
            str(p.relative_to(repo)).replace(os.sep, "/")
            for p in (repo / "dishes").rglob("*")
            if p.is_file()
        ]
    return sorted(f for f in files if f.endswith(".md") and "/README" not in f)


def read_bytes(repo: Path, rel_path: str) -> bytes:
    path = repo / rel_path
    if path.exists():
        return path.read_bytes()
    return run_git(repo, "show", f"HEAD:{rel_path}")


def read_text(repo: Path, rel_path: str) -> str:
    return read_bytes(repo, rel_path).decode("utf-8", errors="ignore")


def clean_line(line: str) -> str:
    line = IMAGE_MD_RE.sub("", line)
    line = IMAGE_HTML_RE.sub("", line)
    line = line.replace('\\"', '"').replace("**", "").replace("`", "")
    return line.strip()


def strip_suffix(name: str) -> str:
    name = name.strip().lstrip("#").strip()
    name = re.sub(r"[（(][^）)]*[）)]$", "", name).strip()
    return re.sub(r"的?做法$", "", name).strip()


def pick_cover(text: str, rel_path: str, repo_files: set[str]) -> str | None:
    md_dir = os.path.dirname(rel_path)
    pre_section = re.split(r"^##\s", text, maxsplit=1, flags=re.MULTILINE)[0]
    for content in (pre_section, text):
        for match in IMAGE_MD_RE.finditer(content):
            target = re.search(r"\(([^)]+)\)", match.group(0))
            if not target:
                continue
            ref = target.group(1).strip().strip("<>")
            if ref.startswith(("http://", "https://", "data:")):
                continue
            candidate = os.path.normpath(os.path.join(md_dir, ref)).replace(os.sep, "/")
            if candidate in repo_files:
                return candidate

    dir_images = sorted(
        f for f in repo_files
        if os.path.dirname(f) == md_dir and Path(f).suffix.lower() in IMAGE_EXTS
    )
    if not dir_images:
        return None
    dish_name = strip_suffix(Path(rel_path).stem)
    for image in dir_images:
        if Path(image).stem == dish_name:
            return image
    for keyword in ("成品", "摆盘", "封面", "预览"):
        hits = [f for f in dir_images if keyword in Path(f).stem]
        if hits:
            return hits[0]
    return dir_images[0]


def extract_sections(text: str) -> dict[str, list[str]]:
    sections: dict[str, list[str]] = {}
    current = ""
    for raw in text.splitlines():
        if raw.startswith("## "):
            current = raw[3:].strip()
            sections.setdefault(current, [])
            continue
        if current:
            sections[current].append(raw)
    return sections


def find_section(sections: dict[str, list[str]], *keywords: str) -> list[str]:
    for title, lines in sections.items():
        if any(keyword in title for keyword in keywords):
            return lines
    return []


def parse_ingredients(sections: dict[str, list[str]]) -> list[dict[str, str]]:
    base_lines = find_section(sections, "原料", "食材", "材料")
    calc_lines = find_section(sections, "计算", "用量", "份量")

    base_items: list[dict[str, str]] = []
    for line in base_lines:
        if line.lstrip().startswith("#"):
            continue
        item = LIST_RE.match(line)
        if not item:
            continue
        name = clean_line(item.group(1))
        name = re.sub(r"[（(][^）)]*[）)]", "", name).strip()
        if not name or name.endswith(TOOL_SUFFIXES):
            continue
        if any(keyword in name for keyword in TOOL_KEYWORDS):
            continue
        amount = ""
        spaced = AMOUNT_SPACE_RE.match(name)
        if spaced:
            name, amount = spaced.group(1).strip(), spaced.group(2).strip()
        for existing in base_items:
            if existing["name"] == name:
                break
        else:
            base_items.append({"name": name[:32], "amount": amount[:64]})

    amounts: dict[str, str] = {}
    for line in calc_lines:
        text = clean_line(line)
        if not text or text.startswith(("|", "#")) or "每份" in text or text.endswith(("：", ":")):
            continue
        item = LIST_RE.match(line)
        if item:
            text = clean_line(item.group(1))
        match = AMOUNT_RE.match(text) or AMOUNT_SPACE_RE.match(text)
        if match:
            name, amount = match.group(1).strip(), match.group(2).strip()
            amounts[name] = amount
        else:
            amounts.setdefault(text, "")

    result: list[dict[str, str]] = []
    used: set[str] = set()
    for item in base_items:
        amount = item["amount"]
        if not amount:
            for key, value in amounts.items():
                if key == item["name"] or key in item["name"] or item["name"] in key:
                    amount = value
                    used.add(key)
                    break
        result.append({"name": item["name"], "amount": amount[:64]})

    for name, amount in amounts.items():
        if name in used or not name:
            continue
        if any(name in item["name"] or item["name"] in name for item in result):
            continue
        if name.endswith(TOOL_SUFFIXES) or any(keyword in name for keyword in TOOL_KEYWORDS):
            continue
        result.append({"name": name[:32], "amount": amount[:64]})
    return result[:20]


def parse_steps(sections: dict[str, list[str]]) -> list[dict]:
    step_lines = find_section(sections, "操作", "步骤", "做法")
    steps: list[dict] = []
    current: dict | None = None
    current_is_numbered = False
    child_indent: int | None = None
    last_node: dict | None = None
    for raw in step_lines:
        if raw.startswith("###"):
            continue
        text = clean_line(raw)
        if not text or text.startswith(("```", "|")):
            continue
        numbered = NUMBERED_RE.match(raw)
        if numbered:
            content = clean_line(numbered.group(1))
            if content:
                current = {"order": len(steps) + 1, "text": content, "children": []}
                steps.append(current)
                current_is_numbered = True
                child_indent = None
                last_node = current
            continue
        bullet = LIST_RE.match(raw)
        if bullet:
            content = clean_line(bullet.group(1))
            if not content:
                continue
            indent = len(raw) - len(raw.lstrip(" "))
            if current is None or (not current_is_numbered and indent < 2):
                current = {"order": len(steps) + 1, "text": content, "children": []}
                steps.append(current)
                current_is_numbered = False
                child_indent = None
                last_node = current
                continue
            parent = current
            if (current_is_numbered and child_indent is not None
                    and indent >= child_indent + 2 and parent["children"]):
                parent = parent["children"][-1]
            elif not current_is_numbered and indent >= 2 and parent["children"]:
                parent = parent["children"][-1]
            if current_is_numbered and child_indent is None:
                child_indent = indent
            node = {"order": len(parent["children"]) + 1, "text": content, "children": []}
            parent["children"].append(node)
            last_node = node
            continue
        if last_node is not None and not raw.lstrip().startswith("#"):
            last_node["text"] = f"{last_node['text']}{text}"

    def clean_node(node: dict) -> dict | None:
        text_value = node["text"].strip()[:400]
        if not text_value:
            return None
        children = [clean_node(child) for child in node.get("children", [])]
        return {
            "order": node["order"],
            "text": text_value,
            "children": [child for child in children if child][:30],
        }

    cleaned = [clean_node(step) for step in steps]
    return [step for step in cleaned if step][:40]


def parse_description(text: str) -> str:
    lines = text.splitlines()
    body: list[str] = []
    started = False
    for line in lines:
        if line.startswith("# "):
            started = True
            continue
        if not started:
            continue
        if line.startswith("## "):
            break
        cleaned = clean_line(line)
        if not cleaned or cleaned.startswith(("预估", "|", ">")):
            continue
        body.append(cleaned)
        if len(" ".join(body)) >= 512:
            break
    return re.sub(r"\s+", " ", " ".join(body))[:512]


def parse_minutes(text: str) -> int:
    pre_section = re.split(r"^##\s", text, maxsplit=1, flags=re.MULTILINE)[0]
    hours = sum(float(v) for v in HOUR_RE.findall(pre_section))
    minutes = sum(int(v) for v in MINUTE_RE.findall(pre_section))
    total = int(hours * 60) + minutes
    return total if total > 0 else 30


def parse_difficulty(text: str) -> int:
    match = STAR_RE.search(text)
    stars = len(match.group(1)) if match else 1
    if stars <= 2:
        return 1
    if stars == 3:
        return 2
    return 3


def build_tags(name: str, description: str, ingredients: list[dict], minutes: int) -> list[str]:
    corpus = name + description + "".join(i["name"] for i in ingredients)
    tags: list[str] = []
    # 口味标签必须与 App 抽签偏好的选项保持一致：微辣 / 清淡 / 下饭 / 酸甜 / 咸鲜
    if any(k in corpus for k in ("辣", "花椒", "豆瓣", "小米椒", "干辣椒", "辣椒油")):
        tags.append("微辣")
    if any(k in corpus for k in ("蒸", "煮", "炖", "粥", "汤")):
        tags.append("清淡")
    if any(k in corpus for k in ("红烧", "酱", "卤", "下饭")):
        tags.append("下饭")
    if any(k in corpus for k in ("糖", "甜", "蛋糕", "布丁", "醋", "酸", "番茄酱")):
        tags.append("酸甜")
    if any(k in corpus for k in ("生抽", "老抽", "酱油", "蚝油", "盐", "鸡精", "味精", "鲜")):
        tags.append("咸鲜")
    # 非口味标签，仅用于展示，不参与抽签筛选
    if minutes <= 20:
        tags.append("快手")
    if not tags:
        tags.append("家常")
    return tags[:4]


def map_cuisine(category: str, name: str) -> str:
    if category == "soup":
        return "汤羹"
    if category == "aquatic":
        return "水产"
    if category == "dessert":
        return "甜品"
    if category == "meat_dish":
        if "凉拌" in name or "拌" in name:
            return "快手菜"
        return "硬菜"
    if category == "vegetable_dish":
        if "凉拌" in name or "拌" in name:
            return "快手菜"
        return "炒菜"
    if category == "breakfast":
        if "粥" in name:
            return "粥类"
        if any(k in name for k in ("包", "馒头", "花卷")):
            return "蒸点"
        if any(k in name for k in ("饼", "煎")):
            return "饼类"
        if "三明治" in name:
            return "三明治"
        if any(k in name for k in ("燕麦", "麦片", "牛奶")):
            return "奶麦"
        if any(k in name for k in ("玉米", "红薯", "紫薯", "南瓜")):
            return "粗粮"
        return "蛋类"
    if category == "staple":
        if any(k in name for k in ("饺", "馄饨")):
            return "饺子"
        if "面" in name:
            return "面条"
        return "面食"
    return "家常菜"


def sql_escape(value: str) -> str:
    return value.replace("'", "''")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", required=True)
    parser.add_argument("--out", default="docs/recipes.sql")
    parser.add_argument("--image-dir", default="public/images/recipes")
    parser.add_argument("--image-base", default="http://localhost:8080/images/recipes")
    parser.add_argument("--include-dessert", action="store_true")
    parser.add_argument("--limit", type=int, default=0)
    args = parser.parse_args()

    repo = Path(args.repo).resolve()
    out_path = Path(args.out)
    image_dir = Path(args.image_dir)
    image_base = args.image_base.rstrip("/")
    image_dir.mkdir(parents=True, exist_ok=True)

    if args.include_dessert:
        CATEGORY_WHITELIST.add("dessert")

    all_files = list_recipe_files(repo)
    file_set = set(all_files)
    for extra in (repo / "dishes").rglob("*") if not (repo / ".git").exists() else []:
        if extra.is_file():
            file_set.add(str(extra.relative_to(repo)).replace(os.sep, "/"))
    if (repo / ".git").exists():
        for f in run_git(repo, "ls-tree", "-r", "--name-only", "HEAD", "--", "dishes").decode().splitlines():
            file_set.add(f)

    recipes: list[dict] = []
    seen_names: set[str] = set()
    skipped = {"category": 0, "name": 0, "ingredients": 0, "steps": 0, "duplicate": 0}
    image_missing = 0
    image_bytes = 0

    commit = "unknown"
    if (repo / ".git").exists():
        commit = run_git(repo, "rev-parse", "--short", "HEAD").decode().strip()

    for rel_path in all_files:
        if args.limit and len(recipes) >= args.limit:
            break
        parts = rel_path.split("/")
        if len(parts) < 3:
            continue
        category = parts[1]
        if category not in CATEGORY_WHITELIST:
            skipped["category"] += 1
            continue

        text = read_text(repo, rel_path)
        title_match = re.search(r"^#\s+(.+)$", text, re.MULTILINE)
        if not title_match:
            skipped["name"] += 1
            continue
        name = strip_suffix(title_match.group(1))
        if not name or len(name) > 64:
            skipped["name"] += 1
            continue
        if name in seen_names:
            skipped["duplicate"] += 1
            continue

        sections = extract_sections(text)
        ingredients = parse_ingredients(sections)
        steps = parse_steps(sections)
        if not ingredients:
            skipped["ingredients"] += 1
            continue
        if len(steps) < 2:
            skipped["steps"] += 1
            continue

        seen_names.add(name)
        recipes.append({
            "path": rel_path,
            "name": name,
            "description": parse_description(text),
            "cuisine": map_cuisine(category, name),
            "difficulty": parse_difficulty(text),
            "minutes": parse_minutes(text),
            "tags": build_tags(name, parse_description(text), ingredients, parse_minutes(text)),
            "ingredients": ingredients,
            "steps": steps,
            "cover": pick_cover(text, rel_path, file_set),
        })

    recipes.sort(key=lambda item: item["path"])

    lines = [
        "-- HowToCook 一次性导入",
        f"-- 源仓库：https://github.com/Anduin2017/HowToCook",
        f"-- 源 commit：{commit}",
        f"-- 条目数：{len(recipes)}",
        "-- 执行：psql \"$DATABASE_URL\" -f docs/recipes.sql",
        "",
        "BEGIN;",
        "",
    ]

    for index, recipe in enumerate(recipes, start=1):
        recipe_id = 900000000000000000 + index
        image_url: str | None = None
        cover = recipe["cover"]
        if cover:
            ext = Path(cover).suffix.lower()
            if ext == ".jpeg":
                ext = ".jpg"
            if ext in IMAGE_EXTS:
                filename = f"{recipe_id}{ext}"
                target = image_dir / filename
                try:
                    if not target.exists():
                        target.write_bytes(read_bytes(repo, cover))
                        image_bytes += target.stat().st_size
                    image_url = f"{image_base}/{filename}"
                except Exception as exc:  # noqa: BLE001
                    print(f"图片复制失败 {cover}: {exc}", file=sys.stderr)
        if not image_url:
            image_missing += 1
        if image_url and len(image_url) > 512:
            image_url = None

        tags_json = sql_escape(json.dumps(recipe["tags"], ensure_ascii=False))
        ingredients_json = sql_escape(json.dumps(recipe["ingredients"], ensure_ascii=False))
        steps_json = sql_escape(json.dumps(recipe["steps"], ensure_ascii=False))
        image_sql = f"'{sql_escape(image_url)}'" if image_url else "NULL"

        lines.extend([
            "INSERT INTO recipes (",
            "    id, name, description, cuisine_id, difficulty, cook_minutes,",
            "    tags, ingredients, steps, aigc_fields, image_url,",
            "    source, enabled, deleted, create_time, update_time",
            ") SELECT",
            f"    {recipe_id},",
            f"    '{sql_escape(recipe['name'])}',",
            f"    '{sql_escape(recipe['description'])}',",
            "    COALESCE((SELECT id FROM cuisines WHERE name = "
            f"'{sql_escape(recipe['cuisine'])}' AND deleted = 0 LIMIT 1), 1),",
            f"    {recipe['difficulty']},",
            f"    {recipe['minutes']},",
            f"    '{tags_json}'::jsonb,",
            f"    '{ingredients_json}'::jsonb,",
            f"    '{steps_json}'::jsonb,",
            "    '[]'::jsonb,",
            f"    {image_sql},",
            f"    'import', 1, 0, NOW(), NOW()",
            "WHERE NOT EXISTS (",
            f"    SELECT 1 FROM recipes WHERE name = '{sql_escape(recipe['name'])}' AND deleted = 0",
            ");",
            "",
        ])

    lines.extend(["COMMIT;", ""])
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text("\n".join(lines), encoding="utf-8")

    print(f"扫描 {len(all_files)} 个 md，生成 {len(recipes)} 条，写入 {out_path}")
    print(f"跳过：非白名单类目 {skipped['category']}，名称异常 {skipped['name']}，"
          f"缺食材 {skipped['ingredients']}，缺步骤 {skipped['steps']}，重名 {skipped['duplicate']}")
    print(f"封面命中 {len(recipes) - image_missing}，缺图 {image_missing}，"
          f"新增图片 {image_bytes / 1024 / 1024:.1f} MB")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
