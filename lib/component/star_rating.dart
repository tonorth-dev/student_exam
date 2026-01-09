import 'package:flutter/material.dart';

/// 星级评分组件
class StarRating extends StatelessWidget {
  final double rating; // 当前评分 (0.0-5.0，支持小数)
  final int maxRating; // 最大评分
  final double size; // 星星大小
  final Color activeColor; // 激活颜色
  final Color inactiveColor; // 未激活颜色
  final Function(int)? onRatingChanged; // 评分改变回调（整数1-5）
  final bool readOnly; // 是否只读

  const StarRating({
    Key? key,
    this.rating = 0.0,
    this.maxRating = 5,
    this.size = 24.0,
    this.activeColor = Colors.amber,
    this.inactiveColor = Colors.grey,
    this.onRatingChanged,
    this.readOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (index) {
        return GestureDetector(
          onTap: readOnly
              ? null
              : () {
                  if (onRatingChanged != null) {
                    onRatingChanged!(index + 1);
                  }
                },
          child: _buildStar(index),
        );
      }),
    );
  }

  /// 构建单个星星，支持半星显示
  Widget _buildStar(int index) {
    final starValue = index + 1;
    
    if (rating >= starValue) {
      // 完整的星星
      return Icon(
        Icons.star,
        size: size,
        color: activeColor,
      );
    } else if (rating > index && rating < starValue) {
      // 半星
      return Stack(
        children: [
          Icon(
            Icons.star_border,
            size: size,
            color: inactiveColor,
          ),
          ClipRect(
            clipper: _HalfClipper(rating - index),
            child: Icon(
              Icons.star,
              size: size,
              color: activeColor,
            ),
          ),
        ],
      );
    } else {
      // 空星
      return Icon(
        Icons.star_border,
        size: size,
        color: inactiveColor,
      );
    }
  }
}

/// 用于裁剪半星的Clipper
class _HalfClipper extends CustomClipper<Rect> {
  final double fillPercentage;

  _HalfClipper(this.fillPercentage);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * fillPercentage, size.height);
  }

  @override
  bool shouldReclip(_HalfClipper oldClipper) {
    return oldClipper.fillPercentage != fillPercentage;
  }
}
