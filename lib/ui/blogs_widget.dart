// // blogs_widget.dart

// import 'package:flutter/material.dart';
// import 'package:manage_learning/ui/blog_repository.dart';
// import 'package:manage_learning/ui/blogs_create.dart';

// class BlogsWidget extends StatelessWidget {
//   const BlogsWidget({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final BlogRepository blogRepository = BlogRepository();

//     return StreamBuilder<List<Map<String, dynamic>>>(
//       stream: blogRepository.getBlogStream(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         if (snapshot.hasError) {
//           return Center(child: Text('Error: ${snapshot.error}'));
//         }

//         final blogs = snapshot.data ?? [];

//         if (blogs.isEmpty) {
//           return const Center(
//             child: Text(
//                 "No blogs available. Tap the '+' button to add a new blog."),
//           );
//         }

//         return SingleChildScrollView(
//           scrollDirection: Axis.vertical,
//           child: LayoutBuilder(
//             builder: (context, constraints) {
//               int crossAxisCount = constraints.maxWidth > 800 ? 4 : 1;
//               double width =
//                   (constraints.maxWidth - (crossAxisCount - 1) * 10) /
//                       crossAxisCount;

//               return Wrap(
//                 spacing: 10,
//                 runSpacing: 10,
//                 children: List.generate(blogs.length, (index) {
//                   final blog = blogs[index];
//                   final title = blog['title'] ?? 'Untitled';
//                   final markdown = blog['markdown'] ?? '';

//                   return SizedBox(
//                     width: width,
//                     child: Card(
//                       margin: const EdgeInsets.all(8.0),
//                       child: ListTile(
//                         title: Text(title),
//                         subtitle: Text(markdown,
//                             maxLines: 2, overflow: TextOverflow.ellipsis),
//                         trailing: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             IconButton(
//                               icon: const Icon(Icons.edit),
//                               onPressed: () {
//                                 // Logic to edit the blog post
//                                 Navigator.of(context).pushNamed('/blog-updates',
//                                     arguments: BlogData(
//                                       blogId: blog['id'],
//                                     ));
//                               },
//                             ),
//                             IconButton(
//                               icon: const Icon(Icons.delete),
//                               onPressed: () async {
//                                 // Logic to delete the blog post
//                                 await blogRepository.deleteBlogPost(blog['id']);
//                               },
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   );
//                 }),
//               );
//             },
//           ),
//         );
//       },
//     );
//   }
// }
