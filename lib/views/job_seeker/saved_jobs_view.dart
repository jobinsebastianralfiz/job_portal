import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../widgets/job_card.dart';
import 'job_details_view.dart';

class SavedJobsView extends StatelessWidget {
  const SavedJobsView({super.key});

  @override
  Widget build(BuildContext context) {
    final jobProvider = context.watch<JobProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Jobs'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (authProvider.currentUser != null) {
            await jobProvider.loadSavedJobs(authProvider.currentUser!.userId);
          }
        },
        child: jobProvider.savedJobs.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bookmark_outline,
                      size: 64,
                      color: AppColors.grey400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No saved jobs',
                      style: AppTextStyles.h5.copyWith(color: AppColors.grey600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Jobs you save will appear here',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.grey500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Browse Jobs'),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: jobProvider.savedJobs.length,
                itemBuilder: (context, index) {
                  final job = jobProvider.savedJobs[index];
                  return JobCard(
                    job: job,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => JobDetailsView(job: job),
                        ),
                      );
                    },
                    onSave: () {
                      if (authProvider.currentUser != null) {
                        jobProvider.toggleSaveJob(
                          job.jobId,
                          authProvider.currentUser!.userId,
                        );
                      }
                    },
                    isSaved: true,
                  );
                },
              ),
      ),
    );
  }
}
