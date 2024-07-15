class Course {
  final String name;
  final String description;
  final String imageUrl;
  final double rating;
  final int studentCount;
  final List<String> students;

  Course({
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.rating,
    required this.studentCount,
    required this.students,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'rating': rating,
      'studentCount': studentCount,
      'students': students,
    };
  }

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      name: map['name'],
      description: map['description'],
      imageUrl: map['imageUrl'],
      rating: map['rating'],
      studentCount: map['studentCount'],
      students: List<String>.from(map['students']),
    );
  }
}
