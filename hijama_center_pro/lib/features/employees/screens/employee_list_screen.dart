import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/employees_provider.dart';

class EmployeeListScreen extends ConsumerStatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  ConsumerState<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends ConsumerState<EmployeeListScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  void _showAddEmployeeDialog() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Register New Staff Account'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Staff Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter staff name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Staff Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (val) => val == null || !val.contains('@') ? 'Enter a valid email' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Temporary Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (val) => val == null || val.length < 6 ? 'Password must be at least 6 characters' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;

              Navigator.pop(context);
              setState(() => _isLoading = true);

              final success = await ref.read(employeesRepositoryProvider).createEmployee({
                'name': _nameController.text.trim(),
                'email': _emailController.text.trim(),
                'password': _passwordController.text,
              });

              setState(() => _isLoading = false);

              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Staff account registered successfully!'),
                      backgroundColor: AppColors.primaryGreen,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to register employee. Email may be already taken.'),
                      backgroundColor: AppColors.warningRed,
                    ),
                  );
                }
              }
            },
            child: const Text('Register'),
          ),
        ],
      ),
    );
  }

  void _deleteEmployee(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Staff Account?'),
        content: Text('Are you sure you want to delete the account for therapist $name? They will not be able to log in anymore.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.warningRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await ref.read(employeesRepositoryProvider).deleteEmployee(id);
      setState(() => _isLoading = false);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Staff member deleted successfully.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete staff member.')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final employeesAsync = ref.watch(employeesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.employees),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(employeesListProvider);
              },
              child: employeesAsync.when(
                data: (employees) {
                  if (employees.isEmpty) {
                    return const Center(
                      child: Text('No employee staff accounts registered yet.'),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: employees.length,
                    itemBuilder: (context, index) {
                      final emp = employees[index];
                      final id = emp['id'];
                      final name = emp['name'];
                      final email = emp['email'];
                      final sessions = emp['sessions_served'] ?? '0';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
                            child: const Icon(Icons.badge, color: AppColors.primaryGreen),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Email: $email', style: const TextStyle(fontSize: 13)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.health_and_safety, color: AppColors.primaryGreen, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$sessions sessions completed',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.warningRed),
                            onPressed: () => _deleteEmployee(id, name),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
                error: (e, _) => Center(child: Text('Error loading employees: $e')),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        onPressed: _showAddEmployeeDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
