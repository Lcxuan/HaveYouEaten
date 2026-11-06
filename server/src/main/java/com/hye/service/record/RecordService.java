package com.hye.service.record;

import com.hye.common.pojo.PageResult;
import com.hye.controller.record.dto.RecordCreateDTO;
import com.hye.controller.record.dto.RecordListDTO;
import com.hye.controller.record.vo.RecordVO;

/**
 * 吃过记录业务接口。
 */
public interface RecordService {

    /**
     * 记一笔：写入当前用户的吃饭记录。
     *
     * @param dto 记录参数
     * @return 记录 id
     */
    Long create(RecordCreateDTO dto);

    /**
     * 分页查询当前用户最近 N 天的记录，按吃饭时间倒序。
     *
     * @param dto 查询参数：天数、页码、每页条数
     * @return 分页结果
     */
    PageResult<RecordVO> listRecent(RecordListDTO dto);
}
