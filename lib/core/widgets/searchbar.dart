// // import 'package:chat/core/theme/theme.dart';
// // import 'package:flutter/material.dart';

// // class CustomSearchBar extends StatelessWidget {
// //   final Function callback;

// //   const CustomSearchBar({super.key, required this.callback});

// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
// //       decoration: BoxDecoration(
// //         color: AppColors.secondaryBackground,
// //         borderRadius: BorderRadius.all(Radius.circular(8.0)),
// //       ),
// //       child: Row(
// //         crossAxisAlignment: CrossAxisAlignment.center,
// //         children: [
// //           const Icon(
// //             Icons.search_rounded,
// //             size: 24,
// //             color: AppColors.onSecondaryBackground,
// //           ),
// //           const SizedBox(width: 10),
// //           Text(
// //             "Search",
// //             style: Theme.of(context).textTheme.titleSmall,
// //             overflow: TextOverflow.ellipsis,
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// import 'package:chat/core/theme/theme.dart';
// import 'package:flutter/material.dart';

// class CustomSearchBar extends StatelessWidget {
//   final Function(String) callback;

//   const CustomSearchBar({super.key, required this.callback});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
//       decoration: BoxDecoration(
//         color: AppColors.secondaryBackground,
//         borderRadius: const BorderRadius.all(Radius.circular(8.0)),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           const Icon(
//             Icons.search_rounded,
//             size: 24,
//             color: AppColors.onSecondaryBackground,
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: TextField(
//               onChanged: callback,
//               icon
//               style: Theme.of(context).textTheme.titleSmall,
//               decoration: InputDecoration(
//                 hintText: "Search",
//                 hintStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
//                   color: AppColors.onSecondaryBackground.withValues(alpha: 0.6),
//                 ),
//                 border: InputBorder.none,
//                 isDense: true,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
