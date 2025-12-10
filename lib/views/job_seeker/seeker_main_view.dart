import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/application_provider.dart';
import '../../models/job_model.dart';
import '../widgets/job_card.dart';
import '../widgets/filter_bottom_sheet.dart';
import 'job_details_view.dart';
import 'applications_view.dart';
import 'seeker_profile_view.dart';
import 'saved_jobs_view.dart';

class SeekerMainView extends StatefulWidget {
  const SeekerMainView({super.key});

  @override
  State<SeekerMainView> createState() => _SeekerMainViewState();
}

class _SeekerMainViewState extends State<SeekerMainView> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Schedule the data loading after the first frame to avoid calling
    // notifyListeners during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    final jobProvider = context.read<JobProvider>();
    final applicationProvider = context.read<ApplicationProvider>();

    jobProvider.loadJobs(refresh: true);

    if (authProvider.currentUser != null) {
      jobProvider.loadSavedJobs(authProvider.currentUser!.userId);
      applicationProvider.loadMyApplications(authProvider.currentUser!.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _SeekerHomePage(),
      const _SearchPage(),
      const ApplicationsView(),
      const SeekerProfileView(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.grey500,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            activeIcon: Icon(Icons.description),
            label: 'Applications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _SeekerHomePage extends StatelessWidget {
  const _SeekerHomePage();

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final jobProvider = context.watch<JobProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('JobPortal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SavedJobsView()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          jobProvider.loadJobs(refresh: true);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_getGreeting()}, ${user?.firstName ?? 'User'}!',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Find Your Dream Job',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        // Switch to search tab
                        final state = context.findAncestorStateOfType<_SeekerMainViewState>();
                        state?.setState(() {
                          state._currentIndex = 1;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: AppColors.grey400),
                            const SizedBox(width: 12),
                            Text(
                              'Search jobs, companies...',
                              style: TextStyle(
                                color: AppColors.grey500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Quick Stats
              Consumer<ApplicationProvider>(
                builder: (context, appProvider, _) {
                  return Row(
                    children: [
                      _QuickStatCard(
                        title: 'Applied',
                        count: appProvider.applications.length,
                        icon: Icons.send,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      _QuickStatCard(
                        title: 'Interview',
                        count: appProvider.interviewCount,
                        icon: Icons.event,
                        color: AppColors.statusInterview,
                      ),
                      const SizedBox(width: 12),
                      _QuickStatCard(
                        title: 'Saved',
                        count: jobProvider.savedJobs.length,
                        icon: Icons.bookmark,
                        color: AppColors.accent,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Categories
              Text(
                'Categories',
                style: AppTextStyles.h5,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _CategoryCard(
                      title: 'Technology',
                      icon: Icons.computer,
                      color: Colors.blue,
                      onTap: () => _filterByCategory(context, 'Technology'),
                    ),
                    _CategoryCard(
                      title: 'Design',
                      icon: Icons.palette,
                      color: Colors.purple,
                      onTap: () => _filterByCategory(context, 'Design'),
                    ),
                    _CategoryCard(
                      title: 'Marketing',
                      icon: Icons.trending_up,
                      color: Colors.orange,
                      onTap: () => _filterByCategory(context, 'Marketing'),
                    ),
                    _CategoryCard(
                      title: 'Finance',
                      icon: Icons.attach_money,
                      color: Colors.green,
                      onTap: () => _filterByCategory(context, 'Finance'),
                    ),
                    _CategoryCard(
                      title: 'Healthcare',
                      icon: Icons.health_and_safety,
                      color: Colors.red,
                      onTap: () => _filterByCategory(context, 'Healthcare'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Recent Jobs Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Jobs',
                    style: AppTextStyles.h5,
                  ),
                  TextButton(
                    onPressed: () {
                      final state = context.findAncestorStateOfType<_SeekerMainViewState>();
                      state?.setState(() {
                        state._currentIndex = 1;
                      });
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Job List
              if (jobProvider.isLoading && jobProvider.jobs.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (jobProvider.jobs.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.work_outline,
                          size: 64,
                          color: AppColors.grey400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No jobs available',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.grey500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Check back later for new opportunities',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: jobProvider.jobs.take(5).length,
                  itemBuilder: (context, index) {
                    final job = jobProvider.jobs[index];
                    return JobCard(
                      job: job,
                      onTap: () => _navigateToJobDetails(context, job),
                      onSave: () => _toggleSaveJob(context, job),
                      isSaved: jobProvider.savedJobs.any((j) => j.jobId == job.jobId),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _filterByCategory(BuildContext context, String category) {
    context.read<JobProvider>().filterJobs({'category': category});
    final state = context.findAncestorStateOfType<_SeekerMainViewState>();
    state?.setState(() {
      state._currentIndex = 1;
    });
  }

  void _navigateToJobDetails(BuildContext context, JobModel job) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobDetailsView(job: job),
      ),
    );
  }

  void _toggleSaveJob(BuildContext context, JobModel job) {
    final authProvider = context.read<AuthProvider>();
    final jobProvider = context.read<JobProvider>();

    if (authProvider.currentUser != null) {
      jobProvider.toggleSaveJob(job.jobId, authProvider.currentUser!.userId);
    }
  }
}

class _QuickStatCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  const _QuickStatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: AppTextStyles.h4.copyWith(color: color),
            ),
            Text(
              title,
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTextStyles.labelSmall.copyWith(color: color),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchPage extends StatefulWidget {
  const _SearchPage();

  @override
  State<_SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<_SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Map<String, dynamic>? _activeFilters;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final jobProvider = context.read<JobProvider>();
      if (!jobProvider.isLoading && jobProvider.hasMore) {
        jobProvider.loadJobs();
      }
    }
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        initialFilters: _activeFilters,
        onApply: (filters) {
          setState(() {
            _activeFilters = filters;
          });
          context.read<JobProvider>().filterJobs(filters);
        },
        onClear: () {
          setState(() {
            _activeFilters = null;
          });
          context.read<JobProvider>().clearFilters();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobProvider = context.watch<JobProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Jobs'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilters,
              ),
              if (_activeFilters != null && _activeFilters!.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search jobs, companies, skills...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          jobProvider.clearFilters();
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.grey100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  jobProvider.searchJobs(value);
                }
              },
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),

          // Active Filters
          if (_activeFilters != null && _activeFilters!.isNotEmpty)
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._activeFilters!.entries.map((entry) {
                    if (entry.value == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(
                          entry.value.toString(),
                          style: AppTextStyles.labelSmall,
                        ),
                        onDeleted: () {
                          setState(() {
                            _activeFilters!.remove(entry.key);
                          });
                          jobProvider.filterJobs(_activeFilters!);
                        },
                        deleteIconColor: AppColors.grey500,
                        backgroundColor: AppColors.primaryLight.withOpacity(0.2),
                      ),
                    );
                  }),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _activeFilters = null;
                      });
                      jobProvider.clearFilters();
                    },
                    child: const Text('Clear all'),
                  ),
                ],
              ),
            ),

          // Results Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${jobProvider.jobs.length} jobs found',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),

          // Job List
          Expanded(
            child: jobProvider.isLoading && jobProvider.jobs.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : jobProvider.jobs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: AppColors.grey400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No jobs found',
                              style: AppTextStyles.h5.copyWith(
                                color: AppColors.grey600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your search or filters',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: jobProvider.jobs.length + (jobProvider.hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == jobProvider.jobs.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final job = jobProvider.jobs[index];
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
                              final authProvider = context.read<AuthProvider>();
                              if (authProvider.currentUser != null) {
                                jobProvider.toggleSaveJob(
                                  job.jobId,
                                  authProvider.currentUser!.userId,
                                );
                              }
                            },
                            isSaved: jobProvider.savedJobs.any((j) => j.jobId == job.jobId),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
