import 'package:example/screens/dashboard_screen.dart';
import 'package:example/screens/user_management_screen.dart';
import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import '../models/user.dart';
import 'login_screen.dart';
import 'view_inventory_screen.dart';
import 'manage_inventory_screen.dart';
import 'order_screen.dart';
import 'order_history_screen.dart';
import 'dashboard_screen.dart';
import 'user_management_screen.dart';


class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _authService = AuthService();
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.currentUser;
  }

  bool get _isAdmin => _currentUser?.role == 'admin';

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF547792)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await _authService.logout();
              if (mounted) {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;
    final isMediumScreen = size.width >= 360 && size.width < 600;
    final isLargeScreen = size.width >= 600;

    // Responsive padding
    final horizontalPadding = isSmallScreen ? 16.0 : (isMediumScreen ? 24.0 : 32.0);
    final verticalPadding = isSmallScreen ? 16.0 : 24.0;

    // Responsive font sizes
    final titleFontSize = isSmallScreen ? 18.0 : (isMediumScreen ? 20.0 : 24.0);
    final subtitleFontSize = isSmallScreen ? 12.0 : 14.0;
    final menuTitleSize = isSmallScreen ? 20.0 : 24.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Inventory Menu',
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 20,
          ),
        ),
        backgroundColor: const Color(0xFF213448),
        foregroundColor: const Color(0xFFEAE0CF),
        elevation: 0,
        actions: [
          // User role badge
          Container(
            margin: EdgeInsets.only(right: horizontalPadding),
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: _isAdmin
                  ? const Color(0xFF547792)
                  : const Color(0xFF94B4C1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _isAdmin ? 'ADMIN' : 'USER',
              style: TextStyle(
                fontSize: isSmallScreen ? 10 : 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFEAE0CF),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF213448),
              Color(0xFFEAE0CF),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: isSmallScreen ? 12 : 20),

                        // Welcome Card
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAE0CF),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: isSmallScreen ? 50 : 60,
                                height: isSmallScreen ? 50 : 60,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF213448),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.person,
                                  color: const Color(0xFFEAE0CF),
                                  size: isSmallScreen ? 28 : 32,
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 12 : 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Welcome back!',
                                      style: TextStyle(
                                        fontSize: subtitleFontSize,
                                        color: const Color(0xFF547792).withOpacity(0.8),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _currentUser?.name ?? 'User',
                                      style: TextStyle(
                                        fontSize: titleFontSize,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF213448),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      _currentUser?.email ?? '',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 10 : 12,
                                        color: const Color(0xFF547792),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: isSmallScreen ? 24 : 32),

                        // Menu Title
                        Text(
                          'Main Menu',
                          style: TextStyle(
                            fontSize: menuTitleSize,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFEAE0CF),
                          ),
                        ),

                        SizedBox(height: isSmallScreen ? 12 : 16),

                        // Menu Buttons
                        _buildMenuButton(
                          icon: Icons.visibility,
                          title: 'VIEW INVENTORY',
                          subtitle: 'Browse and search products',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ViewInventoryScreen(),
                              ),
                            );
                          },
                          isSmallScreen: isSmallScreen,
                        ),

                        // Admin Only: Manage Inventory
                        if (_isAdmin) ...[
                          SizedBox(height: isSmallScreen ? 8 : 12),
                          _buildMenuButton(
                            icon: Icons.edit,
                            title: 'MANAGE INVENTORY',
                            subtitle: 'Add, edit, and delete products',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ManageInventoryScreen(),
                                ),
                              );
                            },
                            isAdminOnly: true,
                            isSmallScreen: isSmallScreen,
                          ),
                        ],

                        SizedBox(height: isSmallScreen ? 8 : 12),

                        _buildMenuButton(
                          icon: Icons.shopping_cart,
                          title: 'ORDERING SIMULATION',
                          subtitle: 'Create new orders',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const OrderingScreen(),
                              ),
                            );
                          },
                          isSmallScreen: isSmallScreen,
                        ),

                        SizedBox(height: isSmallScreen ? 8 : 12),

                        _buildMenuButton(
                          icon: Icons.history,
                          title: 'ORDER HISTORY',
                          subtitle: _isAdmin ? 'View all orders' : 'View your orders',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const OrderHistoryScreen(),
                              ),
                            );
                          },
                          isSmallScreen: isSmallScreen,
                        ),
                        // Admin Only: Dashboard
                        if (_isAdmin) ...[
                          SizedBox(height: isSmallScreen ? 8 : 12),
                          _buildMenuButton(
                            icon: Icons.dashboard,
                            title: 'DASHBOARD',
                            subtitle: 'Analytics and statistics',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const DashboardScreen(),
                                ),
                              );
                            },
                            isAdminOnly: true,
                            isSmallScreen: isSmallScreen,
                          ),

                          SizedBox(height: isSmallScreen ? 8 : 12),
                          _buildMenuButton(
                            icon: Icons.people,
                            title: 'USER MANAGEMENT',
                            subtitle: 'Manage users and roles',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const UserManagementScreen(),
                                ),
                              );
                            },
                            isAdminOnly: true,
                            isSmallScreen: isSmallScreen,
                          ),
                        ],

                        SizedBox(height: isSmallScreen ? 16 : 24),

                        // Logout Button
                        _buildMenuButton(
                          icon: Icons.logout,
                          title: 'LOGOUT',
                          subtitle: 'Sign out of your account',
                          onTap: _handleLogout,
                          isDanger: true,
                          isSmallScreen: isSmallScreen,
                        ),

                        SizedBox(height: isSmallScreen ? 16 : 32),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isAdminOnly = false,
    bool isDanger = false,
    bool isSmallScreen = false,
  }) {
    // Responsive sizes
    final iconContainerSize = isSmallScreen ? 48.0 : 56.0;
    final iconSize = isSmallScreen ? 24.0 : 28.0;
    final titleFontSize = isSmallScreen ? 14.0 : 16.0;
    final subtitleFontSize = isSmallScreen ? 11.0 : 13.0;
    final padding = isSmallScreen ? 16.0 : 20.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: const Color(0xFFEAE0CF),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Row(
              children: [
                Container(
                  width: iconContainerSize,
                  height: iconContainerSize,
                  decoration: BoxDecoration(
                    color: isDanger
                        ? Colors.red.shade100
                        : isAdminOnly
                        ? const Color(0xFF547792).withOpacity(0.2)
                        : const Color(0xFF94B4C1).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isDanger
                        ? Colors.red.shade700
                        : isAdminOnly
                        ? const Color(0xFF213448)
                        : const Color(0xFF547792),
                    size: iconSize,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.bold,
                                color: isDanger
                                    ? Colors.red.shade700
                                    : const Color(0xFF213448),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isAdminOnly) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 4 : 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF547792),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'ADMIN',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 8 : 10,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFEAE0CF),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: subtitleFontSize,
                          color: const Color(0xFF547792),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: isDanger
                      ? Colors.red.shade700
                      : const Color(0xFF94B4C1),
                  size: isSmallScreen ? 16 : 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}