/*
Navicat MariaDB Data Transfer

Source Server         : MainMariaDB
Source Server Version : 100406
Source Host           : 192.168.0.28:3306
Source Database       : credit_card

Target Server Type    : MariaDB
Target Server Version : 100406
File Encoding         : 65001

Date: 2019-08-09 10:28:00
*/

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for bank
-- ----------------------------
DROP TABLE IF EXISTS `bank`;
CREATE TABLE `bank` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `full_name` varchar(255) DEFAULT '' COMMENT '银行名称',
  `name` varchar(255) DEFAULT NULL COMMENT '简称',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for card_info
-- ----------------------------
DROP TABLE IF EXISTS `card_info`;
CREATE TABLE `card_info` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL COMMENT '卡片名称',
  `card_no` varchar(255) DEFAULT NULL COMMENT '卡号',
  `last4no` varchar(10) DEFAULT '' COMMENT '最后四位号码',
  `bank` varchar(255) DEFAULT NULL COMMENT '所属银行',
  `valid_date` date DEFAULT NULL,
  `valid_code` varchar(255) DEFAULT NULL COMMENT '安全码',
  `bill_date` int(2) DEFAULT NULL COMMENT '账单日',
  `repayment_days` int(11) DEFAULT NULL,
  `fixed_limit` double(10,2) unsigned zerofill DEFAULT NULL COMMENT '固定额度',
  `temporary_limit` double(10,2) unsigned zerofill DEFAULT NULL COMMENT '临时额度',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for card_type
-- ----------------------------
DROP TABLE IF EXISTS `card_type`;
CREATE TABLE `card_type` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for card_type_related
-- ----------------------------
DROP TABLE IF EXISTS `card_type_related`;
CREATE TABLE `card_type_related` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `card_id` int(11) DEFAULT NULL,
  `type_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;

-- ----------------------------
-- View structure for view_credit_info
-- ----------------------------
DROP VIEW IF EXISTS `view_credit_info`;
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `view_credit_info` AS select `info`.`name` AS `卡片名称`,`info`.`last4no` AS `最后四位`,`bank`.`name` AS `所属银行`,`remain_days`(`info`.`id`) AS `剩余还款日`,`next_bill_days`(`info`.`id`) AS `下次账单间隔`,`info`.`fixed_limit` AS `固定额度`,`info`.`temporary_limit` AS `临时额度`,`last_bill`(`info`.`id`) AS `上次账单日`,`next_bill`(`info`.`id`) AS `下次账单日`,concat('每月',`info`.`bill_date`,'日') AS `账单日`,`info`.`repayment_days` AS `还款日`,`getTypes`(`info`.`id`) AS `卡片类型` from (`card_info` `info` left join `bank` on(`info`.`bank` = `bank`.`id`)) ;

-- ----------------------------
-- Function structure for getTypes
-- ----------------------------
DROP FUNCTION IF EXISTS `getTypes`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `getTypes`(`seq_name` VARCHAR(20)
) RETURNS varchar(64) CHARSET utf8
BEGIN
    DECLARE TEMP VARCHAR(2000);
    SELECT GROUP_CONCAT(`name` SEPARATOR '；') INTO TEMP FROM card_type WHERE id IN (SELECT type_id FROM card_type_related WHERE card_id = seq_name);
    RETURN TEMP;
END
;;
DELIMITER ;

-- ----------------------------
-- Function structure for last_bill
-- ----------------------------
DROP FUNCTION IF EXISTS `last_bill`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `last_bill`(card_id VARCHAR(20)) RETURNS varchar(999) CHARSET utf8
BEGIN
DECLARE TEMP VARCHAR(999);
DECLARE NOWDAY int(2);
DECLARE BILLDATE int(2);
DECLARE BILLDATECHAR VARCHAR(999);
SET NOWDAY = DAY(CURDATE());
SELECT bill_date INTO BILLDATE FROM card_info WHERE ID = card_id;
SET BILLDATECHAR = LPAD(CAST(BILLDATE AS CHAR), 2, '0');
IF NOWDAY < BILLDATE THEN
SELECT CONCAT(extract(year_month from date_add(now(), interval -1 month)),BILLDATECHAR) INTO TEMP;
ELSE
SELECT CONCAT(extract(year_month from now()),BILLDATECHAR) INTO TEMP;
END IF;
RETURN TEMP;
END
;;
DELIMITER ;

-- ----------------------------
-- Function structure for next_bill
-- ----------------------------
DROP FUNCTION IF EXISTS `next_bill`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `next_bill`(card_id VARCHAR(20)) RETURNS varchar(999) CHARSET utf8
BEGIN
DECLARE TEMP VARCHAR(999);
DECLARE NOWDAY int(2);
DECLARE BILLDATE int(2);
DECLARE BILLDATECHAR VARCHAR(999);
SET NOWDAY = DAY(CURDATE());
SELECT bill_date INTO BILLDATE FROM card_info WHERE ID = card_id;
SET BILLDATECHAR = LPAD(CAST(BILLDATE AS CHAR), 2, '0');


IF NOWDAY = BILLDATE THEN
SELECT '就是今天' as aaa INTO TEMP;
END IF;
IF NOWDAY < BILLDATE THEN
SELECT CONCAT(extract(year_month from now()),BILLDATECHAR) INTO TEMP;
END IF;
IF NOWDAY > BILLDATE THEN
SELECT CONCAT(extract(year_month from date_add(now(), interval + 1 month)),BILLDATECHAR) INTO TEMP;
END IF;


RETURN TEMP;
END
;;
DELIMITER ;

-- ----------------------------
-- Function structure for next_bill_days
-- ----------------------------
DROP FUNCTION IF EXISTS `next_bill_days`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `next_bill_days`(card_id VARCHAR(20)) RETURNS varchar(999) CHARSET utf8
BEGIN
DECLARE TEMP VARCHAR(999);
DECLARE LASTBILL DATE;

DECLARE REPAYMENTDAYS INT(2);

SELECT STR_TO_DATE(next_bill(card_id), '%Y%m%d') INTO LASTBILL;

SELECT TIMESTAMPDIFF(DAY,NOW(),LASTBILL) INTO TEMP; 

RETURN TEMP;
END
;;
DELIMITER ;

-- ----------------------------
-- Function structure for remain_days
-- ----------------------------
DROP FUNCTION IF EXISTS `remain_days`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `remain_days`(card_id VARCHAR(20)) RETURNS varchar(999) CHARSET utf8
BEGIN
DECLARE TEMP VARCHAR(999);
DECLARE LASTBILL DATE;
DECLARE CUTOFFDAY DATE;
DECLARE REPAYMENTDAYS INT(2);
SELECT REPAYMENT_DAYS INTO REPAYMENTDAYS FROM CARD_INFO WHERE ID = card_id;
SELECT STR_TO_DATE(last_bill(card_id), '%Y%m%d') INTO LASTBILL;
SELECT date_add(LASTBILL, interval + REPAYMENTDAYS DAY) INTO CUTOFFDAY;
SELECT TIMESTAMPDIFF(DAY,NOW(),CUTOFFDAY) INTO TEMP; 

RETURN TEMP;
END
;;
DELIMITER ;
