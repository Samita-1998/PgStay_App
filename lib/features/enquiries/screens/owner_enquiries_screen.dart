import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pgstay/core/theme/app_theme.dart';
import 'package:pgstay/features/enquiries/providers/enquiries_provider.dart';
import 'package:pgstay/features/enquiries/models/enquiry_model.dart';
import 'package:pgstay/core/widgets/custom_app_bar.dart';
import 'package:pgstay/features/pg_listing/providers/pg_listing_provider.dart';

class OwnerEnquiriesScreen extends ConsumerStatefulWidget {
  const OwnerEnquiriesScreen({super.key});

  @override
  ConsumerState<OwnerEnquiriesScreen> createState() =>
      _OwnerEnquiriesScreenState();
}

class _OwnerEnquiriesScreenState extends ConsumerState<OwnerEnquiriesScreen>
    with SingleTickerProviderStateMixin {
  int _currentPage = 1;
  final List<EnquiryModel> _enquiries = [];
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String _searchQuery = '';
  String _selectedPg = 'All PGs';
  String _selectedStatus = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(paginatedEnquiriesProvider(_currentPage));
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: 'Enquiries',
        showBackButton: true,
        showLeading: true,
        pinnedSCurve: true,
        isCompact: true,
        backgroundColor: AppTheme.backgroundLight,
        onLeadingPressed: () {
          Navigator.of(context).pop();
        },
      ),
      body: Padding(
        padding: EdgeInsets.only(
          top: 70 + MediaQuery.of(context).padding.top + 32,
        ),
        child: Column(
          children: [
            _buildFilterBar(isSmallScreen),
            Expanded(
              child: asyncData.when(
                data: (newEnquiries) {
                  if (_currentPage == 1) {
                    _enquiries.clear();
                  }

                  for (var item in newEnquiries) {
                    if (!_enquiries.any((e) => e.id == item.id)) {
                      _enquiries.add(item);
                    }
                  }

                  if (newEnquiries.length < 10) {
                    _hasMoreData = false;
                  }

                  if (_enquiries.isEmpty) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.accentColor.withOpacity(0.1),
                                    AppTheme.accentColor.withOpacity(0.05),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.inbox_outlined,
                                size: 60,
                                color: AppTheme.accentColor.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No enquiries yet',
                              style: GoogleFonts.inter(
                                fontSize: isSmallScreen ? 20 : 22,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Incoming enquiries from tenants will appear here',
                              style: GoogleFonts.inter(
                                color: AppTheme.textSecondary,
                                fontSize: isSmallScreen ? 13 : 14,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.refresh_rounded,
                                    size: 18,
                                    color: AppTheme.accentColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Pull down to refresh',
                                    style: GoogleFonts.inter(
                                      color: AppTheme.accentColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final filteredEnquiries = _enquiries.where((e) {
                    final nameMatches =
                        _searchQuery.isEmpty ||
                        (e.user?.name?.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ) ??
                            false);
                    final pgMatches =
                        _selectedPg == 'All PGs' || e.pg?.name == _selectedPg;
                    final statusMatches =
                        _selectedStatus == 'All' ||
                        e.status.toLowerCase().replaceAll(' ', '') ==
                            _selectedStatus.toLowerCase().replaceAll(' ', '');
                    return nameMatches && pgMatches && statusMatches;
                  }).toList();

                  return RefreshIndicator(
                    onRefresh: () async {
                      setState(() {
                        _currentPage = 1;
                        _hasMoreData = true;
                      });
                      await ref.refresh(paginatedEnquiriesProvider(1).future);
                    },
                    color: AppTheme.accentColor,
                    backgroundColor: Colors.white,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: filteredEnquiries.isEmpty && _enquiries.isNotEmpty
                          ? Center(
                              child: Text('No enquiries match your filters.'),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.fromLTRB(
                                isSmallScreen ? 16 : 20,
                                16,
                                isSmallScreen ? 16 : 20,
                                100,
                              ),
                              itemCount:
                                  filteredEnquiries.length +
                                  (_hasMoreData &&
                                          _searchQuery.isEmpty &&
                                          _selectedPg == 'All PGs' &&
                                          _selectedStatus == 'All'
                                      ? 1
                                      : 0),
                              itemBuilder: (context, index) {
                                if (index == filteredEnquiries.length) {
                                  return _buildLoadMoreButton(isSmallScreen);
                                }
                                final enquiry = filteredEnquiries[index];
                                return _buildEnquiryCard(
                                  enquiry,
                                  isSmallScreen,
                                  index,
                                );
                              },
                            ),
                    ),
                  );
                },
                loading: () => _enquiries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.accentColor,
                                    AppTheme.accentColor.withOpacity(0.6),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 25,
                                  height: 25,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Loading enquiries...',
                              style: GoogleFonts.inter(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.accentColor,
                        ),
                      ),
                error: (err, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.error.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: AppTheme.error.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Failed to load enquiries',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please check your connection and try again',
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          ref.refresh(paginatedEnquiriesProvider(_currentPage));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Retry',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(bool isSmallScreen) {
    final ownerPgsAsync = ref.watch(ownerPgsProvider);
    final Set<String> pgNames = {'All PGs'};
    ownerPgsAsync.whenData((pgs) {
      pgNames.addAll(pgs.map((pg) => pg.name));
    });

    final statuses = [
      'All',
      'interested',
      'contacted',
      'visited',
      'dealDone',
      'rejected',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        border: Border(bottom: BorderSide(color: AppTheme.surfaceBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Search Bar
              Expanded(
                flex: isSmallScreen ? 2 : 1,
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by user name...',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppTheme.textHint,
                      size: 20,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.surfaceBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.surfaceBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.accentColor),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // PGs Dropdown
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppTheme.surfaceBorder),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedPg,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.textSecondary,
                      ),
                      items: pgNames.map((name) {
                        return DropdownMenuItem<String>(
                          value: name,
                          child: Text(
                            name,
                            style: GoogleFonts.inter(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedPg = val;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Status Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: statuses.map((status) {
                final isSelected = _selectedStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedStatus = status;
                        });
                      }
                    },
                    selectedColor: AppTheme.accentColor,
                    labelStyle: GoogleFonts.inter(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      fontSize: 13,
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.accentColor
                          : AppTheme.surfaceBorder,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton(bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.accentColor.withOpacity(0.1),
                AppTheme.accentColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: TextButton(
            onPressed: () {
              setState(() {
                _currentPage++;
              });
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 24 : 32,
                vertical: isSmallScreen ? 10 : 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Load More',
                  style: GoogleFonts.inter(
                    color: AppTheme.accentColor,
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallScreen ? 13 : 14,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_downward_rounded,
                  size: 18,
                  color: AppTheme.accentColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnquiryCard(
    EnquiryModel enquiry,
    bool isSmallScreen,
    int index,
  ) {
    int days = 0;
    try {
      days = DateTime.now()
          .difference(DateTime.parse(enquiry.createdAt).toLocal())
          .inDays;
    } catch (_) {}
    Color statusColor = _getCardColor(enquiry.status);

    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => _showActionBottomSheet(enquiry),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: statusColor, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: statusColor.withOpacity(0.1),
                          backgroundImage:
                              (enquiry.user?.picture != null &&
                                  enquiry.user!.picture!.isNotEmpty)
                              ? NetworkImage(enquiry.user!.picture!)
                              : null,
                          child:
                              (enquiry.user?.picture == null ||
                                  enquiry.user!.picture!.isEmpty)
                              ? Icon(
                                  Icons.person_outline_rounded,
                                  color: statusColor,
                                  size: 20,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // User Info & Status
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    enquiry.user?.name ?? 'Unknown',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: AppTheme.textPrimary,
                                      letterSpacing: -0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    enquiry.status.toUpperCase(),
                                    style: GoogleFonts.inter(
                                      color: statusColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              enquiry.user?.mobNo1 ??
                                  enquiry.user?.email ??
                                  'No contact info',
                              style: GoogleFonts.inter(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Container(
                      height: 1,

                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppTheme.primary.withOpacity(0.2),
                            AppTheme.primary.withOpacity(0.4),
                            AppTheme.primary.withOpacity(0.2),
                            Colors.transparent,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.apartment_rounded,
                            size: 16,
                            color: AppTheme.textHint,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              enquiry.pg?.name ?? 'Unknown PG',
                              style: GoogleFonts.inter(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.bed_rounded,
                            size: 16,
                            color: AppTheme.textHint,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              enquiry.post?.title ?? 'Room',
                              style: GoogleFonts.inter(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (enquiry.staffRemarks != null &&
                      enquiry.staffRemarks!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.comment_rounded,
                            size: 14,
                            color: AppTheme.accentColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              enquiry.staffRemarks!,
                              style: GoogleFonts.inter(
                                color: AppTheme.textSecondary,
                                fontStyle: FontStyle.italic,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: AppTheme.textHint,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            days == 0 ? "Today" : "$days days ago",
                            style: GoogleFonts.inter(
                              color: AppTheme.textHint,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (enquiry.status.toLowerCase().replaceAll(' ', '') == 'dealdone') ...[
                            InkWell(
                              onTap: () {
                                context.push('/onboarding', extra: enquiry);
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppTheme.primary.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  'Onboarding',
                                  style: GoogleFonts.inter(
                                    color: AppTheme.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Row(
                            children: [
                              Text(
                                'Action',
                                style: GoogleFonts.inter(
                                  color: AppTheme.accentColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 10,
                                color: AppTheme.accentColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getCardColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'dealdone':
      case 'deal done':
      case 'confirmed':
      case 'paid':
        return const Color(0xFF4CAF50);
      case 'rejected':
      case 'cancelled':
      case 'inventoryfull':
        return const Color(0xFFE53935);
      case 'interested':
        return const Color(0xFFF07B3F);
      case 'visited':
        return const Color(0xFF8E24AA);
      case 'contacted':
        return const Color(0xFF1E88E5);
      case 'pending':
      default:
        return const Color(0xFFF07B3F);
    }
  }

  void _showActionBottomSheet(EnquiryModel enquiry) {
    String selectedStatus = enquiry.status.toLowerCase();

    // Map API status variations
    if (selectedStatus == 'dealdone' ||
        selectedStatus == 'confirmed' ||
        selectedStatus == 'deal done') {
      selectedStatus = 'dealDone';
    } else if (selectedStatus == 'inventoryfull' ||
        selectedStatus == 'cancelled') {
      selectedStatus = 'rejected';
    }

    final List<String> statuses = [
      'interested',
      'contacted',
      'visited',
      'rejected',
      'dealDone',
    ];

    if (!statuses.contains(selectedStatus)) {
      selectedStatus = 'interested';
    }

    final TextEditingController remarksController = TextEditingController(
      text: enquiry.staffRemarks ?? '',
    );
    bool isSaving = false;

    // Professional subtle colors for statuses
    final Map<String, Map<String, dynamic>> statusConfig = {
      'interested': {
        'label': 'Interested',
        'icon': Icons.bookmark_border_rounded,
        'color': const Color(0xFFF07B3F),
      },
      'contacted': {
        'label': 'Contacted',
        'icon': Icons.phone_in_talk_rounded,
        'color': const Color(0xFF1E88E5),
      },
      'visited': {
        'label': 'Visited',
        'icon': Icons.directions_walk_rounded,
        'color': const Color(0xFF8E24AA),
      },
      'rejected': {
        'label': 'Rejected',
        'icon': Icons.block_rounded,
        'color': const Color(0xFFE53935),
      },
      'dealDone': {
        'label': 'Deal Done',
        'icon': Icons.check_circle_outline_rounded,
        'color': const Color(0xFF4CAF50),
      },
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              margin: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + kToolbarHeight,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Professional Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.edit_note_rounded,
                            color: AppTheme.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Update Status',
                                style: context.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                enquiry.user?.name ?? 'Unknown User',
                                style: context.textTheme.labelMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.grey.shade600,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Gradient Divider requested by user
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppTheme.primary.withOpacity(0.2),
                          AppTheme.primary.withOpacity(0.4),
                          AppTheme.primary.withOpacity(0.2),
                          Colors.transparent,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),

                  // Body
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        left: 24,
                        right: 24,
                        top: 20,
                        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Status',
                            style: context.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Compact, professional wrap for status chips
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: statuses.map((status) {
                              final config = statusConfig[status]!;
                              final isSelected = selectedStatus == status;
                              final Color activeColor = config['color'];

                              return InkWell(
                                onTap: () => setModalState(
                                  () => selectedStatus = status,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? activeColor.withOpacity(0.08)
                                        : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected
                                          ? activeColor.withOpacity(0.3)
                                          : Colors.grey.shade200,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        config['icon'],
                                        size: 16,
                                        color: isSelected
                                            ? activeColor
                                            : Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        config['label'],
                                        style: context.textTheme.labelMedium
                                            ?.copyWith(
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              color: isSelected
                                                  ? activeColor
                                                  : Colors.grey.shade700,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 24),

                          Text(
                            'Remarks (Optional)',
                            style: context.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Minimal textfield
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: TextField(
                              controller: remarksController,
                              maxLines: 2,
                              style: context.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Add internal notes here...',
                                hintStyle: context.textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey.shade400),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(16),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Single clean Save Button
                          ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    setModalState(() => isSaving = true);
                                    try {
                                      final repo = ref.read(
                                        enquiriesRepositoryProvider,
                                      );
                                      await repo.updateEnquiry(enquiry.id, {
                                        'status': selectedStatus,
                                        'staffRemarks': remarksController.text
                                            .trim(),
                                      });
                                      if (mounted) {
                                        Navigator.pop(context);
                                        _showSuccessSnackBar(context);
                                        setState(() {
                                          _currentPage = 1;
                                          _hasMoreData = true;
                                        });
                                        ref.refresh(
                                          paginatedEnquiriesProvider(1).future,
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        _showErrorSnackBar(context, e);
                                        setModalState(() => isSaving = false);
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    'Save Status',
                                    style: context.textTheme.labelLarge
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Helper methods for snackbars
  void _showSuccessSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF27AE60),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Enquiry updated successfully! ✨',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xFF27AE60),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Color(0xFFE74C3C),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  error.toString(),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xFFE74C3C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isSmallScreen) {
    Color badgeColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'interested':
        badgeColor = Colors.orange;
        textColor = Colors.orange;
        icon = Icons.favorite_border_rounded;
        break;
      case 'contacted':
        badgeColor = AppTheme.primary;
        textColor = AppTheme.primary;
        icon = Icons.phone_rounded;
        break;
      case 'visited':
        badgeColor = AppTheme.accentColor;
        textColor = AppTheme.accentColor;
        icon = Icons.visibility_rounded;
        break;
      case 'dealdone':
      case 'confirmed':
        badgeColor = AppTheme.success;
        textColor = AppTheme.success;
        icon = Icons.check_circle_rounded;
        break;
      case 'rejected':
      case 'cancelled':
      case 'inventoryfull':
        badgeColor = AppTheme.error;
        textColor = AppTheme.error;
        icon = Icons.cancel_rounded;
        break;
      default:
        badgeColor = AppTheme.textHint;
        textColor = AppTheme.textSecondary;
        icon = Icons.help_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: GoogleFonts.inter(
              color: textColor,
              fontSize: isSmallScreen ? 9 : 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return 'N/A';
    }
  }
}
