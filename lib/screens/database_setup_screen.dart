// import 'package:flutter/material.dart';
// import '../utils/firebase_seeder.dart';
//
// /// ONE-TIME DATABASE SETUP SCREEN
// /// Show this screen on first launch or add a button in your login screen
// /// After seeding once, you can remove this screen
//
// class DatabaseSetupScreen extends StatefulWidget {
//   const DatabaseSetupScreen({super.key});
//
//   @override
//   State<DatabaseSetupScreen> createState() => _DatabaseSetupScreenState();
// }
//
// class _DatabaseSetupScreenState extends State<DatabaseSetupScreen> {
//   final _seeder = FirebaseSeeder();
//   bool _isSeeding = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFEAE0CF),
//       appBar: AppBar(
//         title: const Text('Database Setup'),
//         backgroundColor: const Color(0xFF213448),
//         foregroundColor: const Color(0xFFEAE0CF),
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               // Icon
//               Container(
//                 width: 120,
//                 height: 120,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   shape: BoxShape.circle,
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.1),
//                       blurRadius: 10,
//                       offset: const Offset(0, 5),
//                     ),
//                   ],
//                 ),
//                 child: const Icon(
//                   Icons.cloud_upload,
//                   size: 60,
//                   color: Color(0xFF213448),
//                 ),
//               ),
//               const SizedBox(height: 32),
//
//               // Title
//               const Text(
//                 'First Time Setup',
//                 style: TextStyle(
//                   fontSize: 28,
//                   fontWeight: FontWeight.bold,
//                   color: Color(0xFF213448),
//                 ),
//               ),
//               const SizedBox(height: 12),
//
//               // Description
//               const Text(
//                 'Click below to populate your database with initial data',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: Color(0xFF547792),
//                 ),
//               ),
//               const SizedBox(height: 8),
//
//               // What will be created
//               Container(
//                 margin: const EdgeInsets.symmetric(vertical: 20),
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(16),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.05),
//                       blurRadius: 10,
//                       offset: const Offset(0, 3),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'This will create:',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF213448),
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     _buildInfoRow(Icons.people, '4 Sample Users'),
//                     _buildInfoRow(Icons.inventory, '12 Products'),
//                     _buildInfoRow(Icons.receipt_long, '2 Sample Orders'),
//                     const SizedBox(height: 12),
//                     const Divider(),
//                     const SizedBox(height: 8),
//                     const Text(
//                       '⚠️ Only run this ONCE',
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Color(0xFF547792),
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               // Seed Database Button
//               SizedBox(
//                 width: double.infinity,
//                 height: 56,
//                 child: ElevatedButton.icon(
//                   onPressed: _isSeeding
//                       ? null
//                       : () async {
//                     setState(() => _isSeeding = true);
//                     await _seeder.seedAllData(context);
//                     setState(() => _isSeeding = false);
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF213448),
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   icon: _isSeeding
//                       ? const SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                     ),
//                   )
//                       : const Icon(Icons.cloud_upload),
//                   label: Text(
//                     _isSeeding ? 'Seeding Database...' : 'Seed Database',
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 16),
//
//               // Skip Button
//               TextButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                 },
//                 child: const Text(
//                   'Skip (I\'ll do it manually)',
//                   style: TextStyle(
//                     color: Color(0xFF547792),
//                     fontSize: 14,
//                   ),
//                 ),
//               ),
//
//               const SizedBox(height: 40),
//
//               // Login Credentials Card
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF547792).withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(
//                     color: const Color(0xFF547792),
//                     width: 1,
//                   ),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Row(
//                       children: [
//                         Icon(Icons.key, color: Color(0xFF547792), size: 20),
//                         SizedBox(width: 8),
//                         Text(
//                           'Default Login Credentials',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: Color(0xFF213448),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 12),
//                     _buildCredentialRow('Admin', 'admin@inventory.com', 'admin123'),
//                     const Divider(height: 16),
//                     _buildCredentialRow('User', 'user@inventory.com', 'user123'),
//                     const Divider(height: 16),
//                     _buildCredentialRow('Test', 'test@test.com', '123456'),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildInfoRow(IconData icon, String text) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Row(
//         children: [
//           Icon(icon, size: 20, color: const Color(0xFF547792)),
//           const SizedBox(width: 12),
//           Text(
//             text,
//             style: const TextStyle(
//               fontSize: 14,
//               color: Color(0xFF213448),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildCredentialRow(String role, String email, String password) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           role,
//           style: const TextStyle(
//             fontSize: 12,
//             fontWeight: FontWeight.bold,
//             color: Color(0xFF547792),
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           'Email: $email',
//           style: const TextStyle(
//             fontSize: 13,
//             color: Color(0xFF213448),
//           ),
//         ),
//         Text(
//           'Password: $password',
//           style: const TextStyle(
//             fontSize: 13,
//             color: Color(0xFF213448),
//           ),
//         ),
//       ],
//     );
//   }
// }