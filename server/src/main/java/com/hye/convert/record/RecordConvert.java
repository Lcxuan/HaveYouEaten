package com.hye.convert.record;

import com.hye.controller.record.vo.RecordVO;
import com.hye.entity.EatRecordDO;
import org.mapstruct.Mapper;
import org.mapstruct.factory.Mappers;

/**
 * 吃过记录对象转换器。
 */
@Mapper
public interface RecordConvert {

    RecordConvert INSTANCE = Mappers.getMapper(RecordConvert.class);

    /**
     * 记录实体转 VO。
     *
     * @param record 记录实体
     * @return 记录 VO
     */
    RecordVO toVO(EatRecordDO record);
}
