import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../providers/data_provider.dart';
import '../../providers/auth_provider.dart';
import 'add_agent_screen.dart';
import 'profile_screen.dart';

class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final team = dataProvider.team;
    final currentUserId = context.watch<AuthProvider>().currentUser?.id;

    final filteredTeam = team.where((u) {
      final name = u.name.toLowerCase();
      final email = u.email.toLowerCase();
      final query = searchQuery.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('MANAGE TEAM', style: TextStyle(letterSpacing: 1.5)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) => setState(() => searchQuery = val),
              decoration: AppTheme.inputDecoration('Search team members...', Icons.search),
            ),
          ),
          Expanded(
            child: filteredTeam.isEmpty 
              ? const Center(child: Text('No team members found.', style: TextStyle(color: AppTheme.textSecondary)))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: filteredTeam.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final user = filteredTeam[index];
                    final isMe = user.id == currentUserId;

                    return Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: user.isActive ? Colors.transparent : AppTheme.errorColor.withAlpha(77), width: 2),
                      ),
                      child: ListTile(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(user: user))),
                        leading: CircleAvatar(
                          backgroundColor: user.isActive ? AppTheme.primaryColor.withAlpha(26) : AppTheme.errorColor.withAlpha(26),
                          child: Text(user.name[0], style: TextStyle(color: user.isActive ? AppTheme.primaryColor : AppTheme.errorColor, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(isMe ? '${user.name} (You)' : user.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: user.isActive ? Colors.white : Colors.grey)),
                        subtitle: Text('${user.role.toUpperCase()} • ${user.location}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        trailing: isMe 
                          ? null 
                          : PopupMenuButton<String>(
                              color: AppTheme.backgroundColor,
                              icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
                              onSelected: (value) {
                                if (value == 'role') {
                                  context.read<DataProvider>().toggleUserRole(user.id);
                                } else if (value == 'status') {
                                  context.read<DataProvider>().toggleUserStatus(user.id);
                                }
                              },
                              itemBuilder: (BuildContext context) => [
                                PopupMenuItem(
                                  value: 'role',
                                  child: Text(user.role == 'admin' ? 'Revoke Admin' : 'Make Admin'),
                                ),
                                PopupMenuItem(
                                  value: 'status',
                                  child: Text(user.isActive ? 'Suspend Agent' : 'Reactivate Agent', style: TextStyle(color: user.isActive ? AppTheme.errorColor : AppTheme.primaryColor)),
                                ),
                              ],
                            ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddAgentScreen())),
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
