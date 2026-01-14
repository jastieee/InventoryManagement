import 'package:flutter/material.dart';
import '/services/firebase_auth_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _authService = AuthService();
  final _searchController = TextEditingController();

  List<Map<String, String>> _users = [];
  List<Map<String, String>> _filteredUsers = [];
  String _filterRole = 'all';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final users = await _authService.getAllUsers();

      if (!mounted) return;

      setState(() {
        _users = users;
        _isLoading = false;
        _applyFilters();
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading users: ${e.toString()}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _applyFilters() {
    List<Map<String, String>> filtered = _users;

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((user) {
        return user['name']!.toLowerCase().contains(query) ||
            user['email']!.toLowerCase().contains(query) ||
            user['username']!.toLowerCase().contains(query);
      }).toList();
    }

    if (_filterRole != 'all') {
      filtered = filtered.where((user) => user['role'] == _filterRole).toList();
    }

    setState(() {
      _filteredUsers = filtered;
    });
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFEAE0CF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter by Role',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF213448),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                _buildFilterChip('All', 'all'),
                _buildFilterChip('Admins', 'admin'),
                _buildFilterChip('Users', 'user'),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterRole == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterRole = value;
          _applyFilters();
        });
        Navigator.pop(context);
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF547792),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF213448),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  void _showUserFormDialog(Map<String, String>? user) {
    final isEdit = user != null;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    final usernameController = TextEditingController(text: user?['username'] ?? '');
    final nameController = TextEditingController(text: user?['name'] ?? '');
    final emailController = TextEditingController(text: user?['email'] ?? '');
    final passwordController = TextEditingController();
    String selectedRole = user?['role'] ?? 'user';

    final formKey = GlobalKey<FormState>();
    bool obscurePassword = true;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFFEAE0CF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isEdit ? 'Edit User' : 'Add New User',
            style: TextStyle(
              color: const Color(0xFF213448),
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 18 : 20,
            ),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Username field
                  TextFormField(
                    controller: usernameController,
                    enabled: !isEdit && !isSubmitting,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixIcon: const Icon(Icons.person),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'Required';
                      if (v!.length < 3) return 'Min 3 characters';
                      if (v.contains(' ')) return 'No spaces allowed';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Name field
                  TextFormField(
                    controller: nameController,
                    enabled: !isSubmitting,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: const Icon(Icons.badge),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'Required';
                      if (v!.length < 2) return 'Min 2 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Email field
                  TextFormField(
                    controller: emailController,
                    enabled: !isEdit && !isSubmitting,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'Required';
                      if (!v!.contains('@') || !v.contains('.')) {
                        return 'Invalid email format';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Password field
                  TextFormField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    enabled: !isSubmitting,
                    decoration: InputDecoration(
                      labelText: isEdit ? 'New Password (optional)' : 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      filled: true,
                      fillColor: Colors.white,
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) {
                      if (!isEdit && (v?.isEmpty ?? true)) return 'Required';
                      if ((v?.isNotEmpty ?? false) && v!.length < 6) {
                        return 'Min 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Role selector
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF94B4C1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.admin_panel_settings, color: Color(0xFF547792)),
                        const SizedBox(width: 12),
                        const Expanded(child: Text('Role')),
                        DropdownButton<String>(
                          value: selectedRole,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: 'user', child: Text('User')),
                            DropdownMenuItem(value: 'admin', child: Text('Admin')),
                          ],
                          onChanged: isSubmitting ? null : (value) {
                            setDialogState(() {
                              selectedRole = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                if (formKey.currentState!.validate()) {
                  setDialogState(() => isSubmitting = true);

                  try {
                    Map<String, dynamic> result;

                    if (isEdit) {
                      result = await _authService.updateUser(
                        username: usernameController.text.trim(),
                        name: nameController.text.trim(),
                        role: selectedRole,
                        newPassword: passwordController.text.isNotEmpty
                            ? passwordController.text
                            : null,
                      );
                    } else {
                      result = await _authService.register(
                        username: usernameController.text.trim(),
                        email: emailController.text.trim(),
                        password: passwordController.text,
                        name: nameController.text.trim(),
                        role: selectedRole,
                      );
                    }

                    setDialogState(() => isSubmitting = false);

                    if (result['success']) {
                      await _loadUsers();
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result['message']),
                            backgroundColor: const Color(0xFF547792),
                          ),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result['message']),
                            backgroundColor: Colors.red.shade700,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    setDialogState(() => isSubmitting = false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red.shade700,
                        ),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF213448),
                foregroundColor: const Color(0xFFEAE0CF),
              ),
              child: isSubmitting
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : Text(isEdit ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, String> user) {
    // Prevent deleting yourself
    final currentUser = _authService.currentUser;
    if (currentUser != null && currentUser.username == user['username']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot delete your own account'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFEAE0CF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete User',
          style: TextStyle(
            color: Colors.red.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this user?',
              style: const TextStyle(
                color: Color(0xFF213448),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Name: ${user['name']}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Username: ${user['username']}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Email: ${user['email']}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                final result = await _authService.deleteUser(user['username']!);

                if (context.mounted) {
                  if (result['success']) {
                    await _loadUsers();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['message']),
                        backgroundColor: const Color(0xFF547792),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['message']),
                        backgroundColor: Colors.red.shade700,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting user: ${e.toString()}'),
                      backgroundColor: Colors.red.shade700,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    final adminCount = _users.where((u) => u['role'] == 'admin').length;
    final userCount = _users.where((u) => u['role'] == 'user').length;

    return Scaffold(
      backgroundColor: const Color(0xFFEAE0CF),
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: const Color(0xFF213448),
        foregroundColor: const Color(0xFFEAE0CF),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterOptions,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF213448),
        ),
      )
          : Column(
        children: [
          // Search bar
          Container(
            color: const Color(0xFF213448),
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _applyFilters(),
              style: const TextStyle(color: Color(0xFFEAE0CF)),
              decoration: InputDecoration(
                hintText: 'Search users...',
                hintStyle: TextStyle(color: const Color(0xFFEAE0CF).withOpacity(0.6)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFEAE0CF)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Color(0xFFEAE0CF)),
                  onPressed: () {
                    _searchController.clear();
                    _applyFilters();
                  },
                )
                    : null,
                filled: true,
                fillColor: const Color(0xFF547792).withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Stats
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${_users.length}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF213448),
                        ),
                      ),
                      const Text(
                        'Total Users',
                        style: TextStyle(fontSize: 13, color: Color(0xFF547792)),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: const Color(0xFF94B4C1),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$adminCount',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF547792),
                        ),
                      ),
                      const Text(
                        'Admins',
                        style: TextStyle(fontSize: 13, color: Color(0xFF547792)),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: const Color(0xFF94B4C1),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$userCount',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF94B4C1),
                        ),
                      ),
                      const Text(
                        'Users',
                        style: TextStyle(fontSize: 13, color: Color(0xFF547792)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // User list
          Expanded(
            child: _filteredUsers.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 80,
                    color: const Color(0xFF547792).withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchController.text.isNotEmpty || _filterRole != 'all'
                        ? 'No users found'
                        : 'No users yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: const Color(0xFF547792).withOpacity(0.7),
                    ),
                  ),
                  if (_searchController.text.isEmpty && _filterRole == 'all') ...[
                    const SizedBox(height: 8),
                    Text(
                      'Tap the button below to add users',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF547792).withOpacity(0.5),
                      ),
                    ),
                  ],
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                return _buildUserCard(user);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserFormDialog(null),
        backgroundColor: const Color(0xFF213448),
        foregroundColor: const Color(0xFFEAE0CF),
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
      ),
    );
  }

  Widget _buildUserCard(Map<String, String> user) {
    final isAdmin = user['role'] == 'admin';
    final currentUser = _authService.currentUser;
    final isCurrentUser = currentUser?.username == user['username'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isAdmin ? const Color(0xFF547792) : const Color(0xFF94B4C1),
          child: Text(
            user['name']![0].toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                user['name']!,
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isAdmin ? const Color(0xFF547792) : const Color(0xFF94B4C1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isAdmin ? 'ADMIN' : 'USER',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            if (isCurrentUser) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'YOU',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('@${user['username']}'),
            Text(user['email']!, style: const TextStyle(fontSize: 12)),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20, color: Color(0xFF547792)),
                  SizedBox(width: 12),
                  Text('Edit'),
                ],
              ),
            ),
            if (!isCurrentUser) // Don't show delete option for current user
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Text('Delete', style: TextStyle(color: Colors.red.shade700)),
                  ],
                ),
              ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              _showUserFormDialog(user);
            } else if (value == 'delete') {
              _showDeleteConfirmation(user);
            }
          },
        ),
      ),
    );
  }
}