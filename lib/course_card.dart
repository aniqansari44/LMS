import 'package:flutter/material.dart';

class CourseCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final double rating;
  final int studentCount;

  CourseCard({
    required this.title,
    required this.imageUrl,
    required this.rating,
    required this.studentCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(imageUrl, height: 100, width: double.infinity, fit: BoxFit.cover),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Icon(Icons.star, color: Colors.orange, size: 16),
                Text(rating.toString()),
                SizedBox(width: 10),
                Text('$studentCount Students'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
