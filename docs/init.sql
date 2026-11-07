-- =============================================================
-- have-you-eaten 数据库初始化脚本
-- =============================================================

-- -------------------------------------------------------------
-- 1. 用户表
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id          BIGINT       NOT NULL PRIMARY KEY,
    password    VARCHAR(64)  NOT NULL,
    nickname    VARCHAR(32),
    phone       VARCHAR(16),
    status      SMALLINT     NOT NULL DEFAULT 1,
    last_login_time TIMESTAMP,
    deleted     SMALLINT     NOT NULL DEFAULT 0,
    create_by   BIGINT,
    update_by   BIGINT,
    create_time TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_time TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE users IS '用户表';
COMMENT ON COLUMN users.password IS '密码（BCrypt 加密存储）';
COMMENT ON COLUMN users.nickname IS '昵称（展示用）';
COMMENT ON COLUMN users.phone IS '手机号（可作为登录标识，唯一）';
COMMENT ON COLUMN users.status IS '状态 0-禁用 1-正常';
COMMENT ON COLUMN users.last_login_time IS '最后登录时间';
COMMENT ON COLUMN users.deleted IS '是否已删除：0-否，1-是';
COMMENT ON COLUMN users.create_by IS '创建人 id';
COMMENT ON COLUMN users.update_by IS '更新人 id';
COMMENT ON COLUMN users.create_time IS '创建时间';
COMMENT ON COLUMN users.update_time IS '更新时间';

-- -------------------------------------------------------------
-- 2. 菜系表
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cuisines (
    id          BIGINT       NOT NULL PRIMARY KEY,
    name         VARCHAR(32)  NOT NULL,
    meal_periods JSONB        NOT NULL DEFAULT '[1, 2, 3, 4]'::jsonb,
    sort         INT          NOT NULL DEFAULT 0,
    status      SMALLINT     NOT NULL DEFAULT 1,
    deleted     SMALLINT     NOT NULL DEFAULT 0,
    create_by   BIGINT,
    update_by   BIGINT,
    create_time TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_time TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE cuisines IS '菜系字典';
COMMENT ON COLUMN cuisines.name IS '菜系名（家常菜/川菜/粤菜等）';
COMMENT ON COLUMN cuisines.meal_periods IS '适用餐段：1-早餐，2-午餐，3-晚餐，4-夜宵';
COMMENT ON COLUMN cuisines.sort IS '排序值，越小越靠前';
COMMENT ON COLUMN cuisines.status IS '状态 0-禁用 1-启用';
COMMENT ON COLUMN cuisines.deleted IS '是否已删除：0-否，1-是';

-- -------------------------------------------------------------
-- 3. 菜谱表
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS recipes (
    id          BIGINT       NOT NULL PRIMARY KEY,
    name        VARCHAR(64)  NOT NULL,
    description VARCHAR(512),
    cuisine_id  BIGINT       NOT NULL,
    difficulty  SMALLINT     NOT NULL DEFAULT 1,
    cook_minutes INT         NOT NULL DEFAULT 30,
    tags        JSONB        NOT NULL DEFAULT '[]'::jsonb,
    ingredients JSONB        NOT NULL DEFAULT '[]'::jsonb,
    steps       JSONB        NOT NULL DEFAULT '[]'::jsonb,
    aigc_fields JSONB        NOT NULL DEFAULT '[]'::jsonb,
    image_url   VARCHAR(512),
    source      VARCHAR(16)  NOT NULL DEFAULT 'ai',
    enabled     SMALLINT     NOT NULL DEFAULT 1,
    deleted     SMALLINT     NOT NULL DEFAULT 0,
    create_by   BIGINT,
    update_by   BIGINT,
    create_time TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_time TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE recipes IS '菜谱库';
COMMENT ON COLUMN recipes.name IS '菜名';
COMMENT ON COLUMN recipes.description IS '简介';
COMMENT ON COLUMN recipes.cuisine_id IS '菜系 id（引用 cuisines 表）';
COMMENT ON COLUMN recipes.difficulty IS '难度 1-简单 2-中等 3-困难';
COMMENT ON COLUMN recipes.cook_minutes IS '烹饪时长（分钟）';
COMMENT ON COLUMN recipes.tags IS '口味标签数组，如 ["辣","下饭"]';
COMMENT ON COLUMN recipes.ingredients IS '食材清单，如 [{"name":"土豆","amount":"2个"}]';
COMMENT ON COLUMN recipes.steps IS '步骤数组，如 [{"order":1,"text":"切丁"}]';
COMMENT ON COLUMN recipes.aigc_fields IS 'AI 生成/改写的字段名数组，取值：description / ingredients / steps / image_url';
COMMENT ON COLUMN recipes.image_url IS '配图地址（AI 生成）';
COMMENT ON COLUMN recipes.source IS '来源：ai-AI 生成（需 AIGC 标识），import-开源菜谱导入，manual-人工录入';
COMMENT ON COLUMN recipes.enabled IS '是否上架参与抽签：0-下架，1-上架';
COMMENT ON COLUMN recipes.deleted IS '是否已删除：0-否，1-是';
COMMENT ON COLUMN recipes.create_by IS '创建人 id';
COMMENT ON COLUMN recipes.update_by IS '更新人 id';
COMMENT ON COLUMN recipes.create_time IS '创建时间';
COMMENT ON COLUMN recipes.update_time IS '更新时间';

-- -------------------------------------------------------------
-- 4. 吃过记录表
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS eat_records (
    id          BIGINT       NOT NULL PRIMARY KEY,
    user_id     BIGINT       NOT NULL,
    recipe_id   BIGINT,
    poi_id      VARCHAR(64),
    name        VARCHAR(64)  NOT NULL,
    source      VARCHAR(16)  NOT NULL DEFAULT 'roulette',
    eaten_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    remark      VARCHAR(255),
    deleted     SMALLINT     NOT NULL DEFAULT 0,
    create_by   BIGINT,
    update_by   BIGINT,
    create_time TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_time TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE eat_records IS '吃过记录';
COMMENT ON COLUMN eat_records.user_id IS '用户 id';
COMMENT ON COLUMN eat_records.recipe_id IS '菜谱 id（在家吃时填写）';
COMMENT ON COLUMN eat_records.poi_id IS '高德 POI id（出去吃时填写）';
COMMENT ON COLUMN eat_records.name IS '名称冗余（菜名/店名，防源数据变化）';
COMMENT ON COLUMN eat_records.source IS '来源 roulette-抽签 manual-手动 ai_recommend-AI 推荐';
COMMENT ON COLUMN eat_records.eaten_at IS '吃饭时间';
COMMENT ON COLUMN eat_records.deleted IS '是否已删除：0-否，1-是';
COMMENT ON COLUMN eat_records.create_by IS '创建人 id';
COMMENT ON COLUMN eat_records.update_by IS '更新人 id';
COMMENT ON COLUMN eat_records.create_time IS '创建时间';
COMMENT ON COLUMN eat_records.update_time IS '更新时间';

-- -------------------------------------------------------------
-- 5. 收藏表
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS favorites (
    id          BIGINT       NOT NULL PRIMARY KEY,
    user_id     BIGINT       NOT NULL,
    target_type VARCHAR(16)  NOT NULL,
    target_id   VARCHAR(64)  NOT NULL,
    name        VARCHAR(64)  NOT NULL,
    deleted     SMALLINT     NOT NULL DEFAULT 0,
    create_by   BIGINT,
    update_by   BIGINT,
    create_time TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_time TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE favorites IS '收藏';
COMMENT ON COLUMN favorites.target_type IS '类型 recipe-菜谱 restaurant-餐厅';
COMMENT ON COLUMN favorites.target_id IS '目标 id（菜谱 id 或高德 POI id）';
COMMENT ON COLUMN favorites.name IS '名称冗余';
COMMENT ON COLUMN favorites.deleted IS '是否已删除：0-否，1-是';
COMMENT ON COLUMN favorites.create_by IS '创建人 id';
COMMENT ON COLUMN favorites.update_by IS '更新人 id';
COMMENT ON COLUMN favorites.create_time IS '创建时间';
COMMENT ON COLUMN favorites.update_time IS '更新时间';

-- -------------------------------------------------------------
-- 6. 黑名单
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS blacklist (
    id           BIGINT       NOT NULL PRIMARY KEY,
    user_id      BIGINT       NOT NULL,
    scope        VARCHAR(16)  NOT NULL,
    target_value VARCHAR(64)  NOT NULL,
    remark       VARCHAR(255),
    deleted      SMALLINT     NOT NULL DEFAULT 0,
    create_by    BIGINT,
    update_by    BIGINT,
    create_time  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_time  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE blacklist IS '黑名单';
COMMENT ON COLUMN blacklist.scope IS '粒度 cuisine-菜系 poi-餐厅 recipe-菜谱';
COMMENT ON COLUMN blacklist.target_value IS '屏蔽值（菜系名 / POI id / 菜谱 id）';
COMMENT ON COLUMN blacklist.remark IS '拉黑原因备注';
COMMENT ON COLUMN blacklist.deleted IS '是否已删除：0-否，1-是';
COMMENT ON COLUMN blacklist.create_by IS '创建人 id';
COMMENT ON COLUMN blacklist.update_by IS '更新人 id';
COMMENT ON COLUMN blacklist.create_time IS '创建时间';
COMMENT ON COLUMN blacklist.update_time IS '更新时间';
