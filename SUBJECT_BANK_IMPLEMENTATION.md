# 专业题库学习页面功能实现文档

## 需求概述

1. 进入页面先获取考生所有的subject_category，渲染为tab（题库一、题库二...）
2. 每个tab加载对应category的题目，支持分页（每页20题）
3. 去掉服务端随机逻辑，改为顺序加载
4. 添加题目评分功能（1-5星）

## 后端实现

### 1. 数据库变更

需要创建题目评分表：

```sql
CREATE TABLE `subject_rating` (
  `id` int NOT NULL AUTO_INCREMENT,
  `student_id` int NOT NULL COMMENT '学生ID',
  `subject_id` int NOT NULL COMMENT '题目ID',
  `rating` tinyint NOT NULL COMMENT '评分(1-5)',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_student_subject` (`student_id`,`subject_id`),
  KEY `idx_subject_id` (`subject_id`),
  KEY `idx_student_id` (`student_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='题目评分表';
```

### 2. 模型层 (model/subject/subject_rating.go)

```go
package subject

import "time"

type SubjectRating struct {
	ID         int       `gorm:"primaryKey;autoIncrement" json:"id"`
	StudentID  int       `gorm:"not null" json:"student_id"`
	SubjectID  int       `gorm:"not null" json:"subject_id"`
	Rating     int       `gorm:"not null" json:"rating"`
	CreateTime time.Time `gorm:"not null;default:CURRENT_TIMESTAMP" json:"create_time"`
	UpdateTime time.Time `gorm:"not null;default:CURRENT_TIMESTAMP" json:"update_time"`
}

func (SubjectRating) TableName() string {
	return "subject_rating"
}
```

### 3. 服务层 (service/subject/subject.go)

需要添加以下方法：

```go
// GetSubjectsByCategoryWithRating 按category顺序获取题目（带评分）
func (s *SubjectService) GetSubjectsByCategoryWithRating(category, studentID, page, pageSize int) ([]*qmodel.RSubject, int64, error) {
	var subjects []*qmodel.Subject
	var total int64
	
	db := s.DB.Model(&qmodel.Subject{})
	db = db.Where("subject_category = ? AND status = ?", category, 2)
	
	if err := db.Count(&total).Error; err != nil {
		return nil, 0, err
	}
	
	offset := (page - 1) * pageSize
	if err := db.Order("id ASC").Offset(offset).Limit(pageSize).Find(&subjects).Error; err != nil {
		return nil, 0, err
	}
	
	// 获取评分
	subjectIDs := make([]int, len(subjects))
	for i, s := range subjects {
		subjectIDs[i] = s.ID
	}
	
	ratings := make(map[int]int)
	if len(subjectIDs) > 0 {
		var ratingList []qmodel.SubjectRating
		s.DB.Where("student_id = ? AND subject_id IN ?", studentID, subjectIDs).Find(&ratingList)
		for _, r := range ratingList {
			ratings[r.SubjectID] = r.Rating
		}
	}
	
	// 转换为RSubject并添加评分
	result := make([]*qmodel.RSubject, len(subjects))
	for i, subject := range subjects {
		result[i] = &qmodel.RSubject{
			ID:              subject.ID,
			Title:           subject.Title,
			TitleEncr:       subject.TitleEncr,
			Answer:          subject.Answer,
			AnswerEncr:      subject.AnswerEncr,
			Cate:            subject.Cate,
			Level:           subject.Level,
			MajorCode:       subject.MajorCode,
			SubjectCategory: subject.SubjectCategory,
			Tag:             subject.Tag,
			Author:          subject.Author,
			BelongYear:      subject.BelongYear,
			Rating:          ratings[subject.ID],
		}
	}
	
	return result, total, nil
}

// SaveSubjectRating 保存或更新题目评分
func (s *SubjectService) SaveSubjectRating(studentID, subjectID, rating int) error {
	var existingRating qmodel.SubjectRating
	err := s.DB.Where("student_id = ? AND subject_id = ?", studentID, subjectID).First(&existingRating).Error
	
	if err == gorm.ErrRecordNotFound {
		// 创建新评分
		newRating := qmodel.SubjectRating{
			StudentID: studentID,
			SubjectID: subjectID,
			Rating:    rating,
		}
		return s.DB.Create(&newRating).Error
	} else if err != nil {
		return err
	}
	
	// 更新现有评分
	return s.DB.Model(&existingRating).Update("rating", rating).Error
}
```

### 4. MajorCode服务层 (service/major_code/major_code.go)

需要添加获取所有category的方法：

```go
// GetAllSubjectCategoriesByJobCode 根据job_code获取所有subject_category
func (s *MajorCodeService) GetAllSubjectCategoriesByJobCode(jobCode string) ([]int, error) {
	var categories []int
	err := s.DB.Model(&MajorCode{}).
		Where("job_code = ?", jobCode).
		Pluck("subject_category", &categories).Error
	return categories, err
}
```

### 5. API层 - 已完成

- ✅ GetStudentSubjectCategories - 获取学生的category列表
- ✅ GetSubjectListForStudent - 修改为按category顺序分页
- ✅ RateSubject - 题目评分API

### 6. 路由注册 (router/stu_client/student.go)

```go
studentRouter.GET("/subject/categories", subjectAPI.GetStudentSubjectCategories)
studentRouter.GET("/subject/list", subjectAPI.GetSubjectListForStudent)
studentRouter.POST("/subject/rate", subjectAPI.RateSubject)
```

## 前端实现

### 1. API层 (lib/api/subject_api.dart)

```dart
/// 获取学生的subject_category列表
static Future<dynamic> getSubjectCategories() async {
  try {
    return await HttpUtil.get("/student/subject/categories");
  } catch (e) {
    print('Error getting subject categories: $e');
    rethrow;
  }
}

/// 获取题目列表（按category分页）
static Future<dynamic> getSubjectList({
  required int subjectCategory,
  int page = 1,
  int pageSize = 20,
}) async {
  try {
    return await HttpUtil.get("/student/subject/list", params: {
      'subject_category': subjectCategory,
      'page': page,
      'pageSize': pageSize,
    });
  } catch (e) {
    print('Error getting subject list: $e');
    rethrow;
  }
}

/// 对题目进行评分
static Future<dynamic> rateSubject({
  required int subjectId,
  required int rating,
}) async {
  try {
    return await HttpUtil.post("/student/subject/rate", params: {
      'subject_id': subjectId,
      'rating': rating,
    });
  } catch (e) {
    print('Error rating subject: $e');
    rethrow;
  }
}
```

### 2. Logic层重构 (lib/app/home/pages/subject_bank/self_research/logic.dart)

需要重构为支持多tab和评分的逻辑：

- 添加category列表管理
- 添加当前选中的tab索引
- 为每个category维护独立的题目列表和分页状态
- 添加评分功能

### 3. View层重构 (lib/app/home/pages/subject_bank/self_research/view.dart)

需要重构为TabBar结构：

- 顶部显示TabBar（题库一、题库二...）
- 每个Tab显示对应category的题目列表
- 题目卡片添加星级评分组件
- 底部分页控件（上一页、下一页、页码）

### 4. 星级评分组件

创建可复用的星级评分组件，支持1-5星评分。

## 实施步骤

### 后端（需要手动完成）

1. ✅ 创建subject_rating表
2. ✅ 创建SubjectRating模型
3. ✅ 在SubjectService中添加GetSubjectsByCategoryWithRating方法
4. ✅ 在SubjectService中添加SaveSubjectRating方法
5. ✅ 在MajorCodeService中添加GetAllSubjectCategoriesByJobCode方法
6. ✅ 在SubjectAPI中添加GetStudentSubjectCategories方法
7. ✅ 修改GetSubjectListForStudent方法
8. ✅ 在SubjectAPI中添加RateSubject方法
9. ⏳ 在路由中注册新的API端点

### 前端（自动完成）

1. ⏳ 在SubjectApi中添加新的API方法
2. ⏳ 重构SelfResearchLogic支持多tab
3. ⏳ 重构SelfResearchPage为TabBar结构
4. ⏳ 创建星级评分组件
5. ⏳ 集成评分功能到题目卡片

## 注意事项

1. 后端的服务层方法需要在对应的service文件中实现
2. 数据库表需要手动创建或通过迁移脚本创建
3. 路由需要在router/stu_client/student.go中注册
4. 前端的SubjectModel需要添加rating字段
5. 评分功能需要实时更新UI，无需刷新页面

## 测试要点

1. 验证category列表正确加载
2. 验证每个tab独立加载题目
3. 验证分页功能正常
4. 验证评分功能可以保存和显示
5. 验证题目顺序加载（非随机）
