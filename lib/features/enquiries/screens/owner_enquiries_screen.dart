import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        pinnedSCurve: true,
      ),
      body: Padding(
        padding: EdgeInsets.only(
          top: 110 + MediaQuery.of(context).padding.top + 32,
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

  Widget _buildEnquiryCard_old(
    EnquiryModel enquiry,
    bool isSmallScreen,
    int index,
  ) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: () {
              _showActionBottomSheet(enquiry);
            },
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.accentColor.withOpacity(0.2),
                              AppTheme.accentColor.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.transparent,
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
                                  size: 28,
                                  color: AppTheme.accentColor,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              enquiry.user?.name ?? 'Unknown User',
                              style: GoogleFonts.inter(
                                fontSize: isSmallScreen ? 15 : 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.phone_rounded,
                                  size: 14,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    enquiry.user?.mobNo1 ??
                                        enquiry.user?.email ??
                                        'No contact info',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _buildStatusBadge(enquiry.status, isSmallScreen),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.accentColor.withOpacity(0.05),
                          AppTheme.accentColor.withOpacity(0.02),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.apartment_rounded,
                                size: 16,
                                color: AppTheme.accentColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Property',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textHint,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    enquiry.pg?.name ?? 'Unknown PG',
                                    style: GoogleFonts.inter(
                                      fontSize: isSmallScreen ? 12 : 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.bed_rounded,
                                size: 16,
                                color: AppTheme.accentColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Room Type',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textHint,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    enquiry.post?.title ?? 'Unknown Post',
                                    style: GoogleFonts.inter(
                                      fontSize: isSmallScreen ? 12 : 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (enquiry.staffRemarks != null &&
                      enquiry.staffRemarks!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.accentColor.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.comment_rounded,
                            size: 14,
                            color: AppTheme.accentColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Remarks: ${enquiry.staffRemarks}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.textHint.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: AppTheme.textHint,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(enquiry.createdAt),
                              style: GoogleFonts.inter(
                                color: AppTheme.textHint,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.accentColor,
                              AppTheme.accentColor.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              _showActionBottomSheet(enquiry);
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Take Action',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
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

  Widget _buildEnquiryCard(
    EnquiryModel enquiry,
    bool isSmallScreen,
    int index,
  ) {
    int days = 0;
    try {
      days = DateTime.now().difference(DateTime.parse(enquiry.createdAt).toLocal()).inDays;
    } catch (_) {}
    Color statusColor = _getCardColor(enquiry.status);

    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 24.0, right: 24.0, left: 8.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background white card with shadow
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left Colored Area
                  Container(
                    width: isSmallScreen ? 100 : 120,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        bottomLeft: Radius.circular(24),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 16,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          enquiry.user?.name ?? 'User',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: isSmallScreen ? 12 : 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        CircleAvatar(
                          radius: isSmallScreen ? 28 : 34,
                          backgroundColor: Colors.white.withOpacity(0.2),
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
                                  color: Colors.white,
                                  size: isSmallScreen ? 28 : 34,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),

                  // Right Area
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Status Banner
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: const BorderRadius.only(
                              bottomRight: Radius.circular(24),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                enquiry.status.toUpperCase(),
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Content
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 32, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                enquiry.pg?.name ?? 'Unknown Property',
                                style: GoogleFonts.inter(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                enquiry.post?.title ?? 'Room details',
                                style: GoogleFonts.inter(
                                  fontSize: isSmallScreen ? 12 : 13,
                                  color: AppTheme.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone_rounded,
                                    size: 14,
                                    color: AppTheme.textHint,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      enquiry.user?.mobNo1 ??
                                          enquiry.user?.email ??
                                          'No contact info',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppTheme.textHint,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Circular overlapping indicator on the right edge
          Positioned(
            right: -24,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$days',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      days == 1 ? 'DAY' : 'DAYS',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Touch target overlay
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                  _showActionBottomSheet(enquiry);
                },
              ),
            ),
          ),
        ],
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

    // Map API status variations to our standard keys
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

    // Status configuration using AppTheme colors
    final Map<String, Map<String, dynamic>> statusConfig = {
      'interested': {
        'label': 'Interested',
        'icon': Icons.favorite_border_rounded,
        'color': Colors.orange,
        'gradient': [Colors.orange.shade400, Colors.orange.shade600],
      },
      'contacted': {
        'label': 'Contacted',
        'icon': Icons.phone_rounded,
        'color': AppTheme.primary,
        'gradient': [AppTheme.primary, AppTheme.primaryDark],
      },
      'visited': {
        'label': 'Visited',
        'icon': Icons.visibility_rounded,
        'color': AppTheme.accentColor,
        'gradient': [AppTheme.accentColor, AppTheme.secondaryColor],
      },
      'rejected': {
        'label': 'Rejected',
        'icon': Icons.cancel_rounded,
        'color': AppTheme.error,
        'gradient': [AppTheme.error, AppTheme.error.withOpacity(0.8)],
      },
      'dealDone': {
        'label': 'Deal Done',
        'icon': Icons.check_circle_rounded,
        'color': AppTheme.success,
        'gradient': [AppTheme.success, AppTheme.success.withOpacity(0.8)],
      },
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentStatusConfig =
                statusConfig[selectedStatus] ?? statusConfig['interested']!;

            return Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusXXL),
                ),
                boxShadow: AppTheme.elevatedShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.textHint.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(AppTheme.radiusXS),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Update Enquiry Status',
                              style: AppTheme.textTheme.displaySmall?.copyWith(
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: currentStatusConfig['gradient'],
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusLG,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    currentStatusConfig['icon'],
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    currentStatusConfig['label'],
                                    style: AppTheme.textTheme.labelSmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMD,
                            ),
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppTheme.textSecondary,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Main content with constrained height
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.only(
                        bottom:
                            MediaQuery.of(context).padding.bottom +
                            20, // Reduced from 100 to 20
                        top: 8,
                        left: 24,
                        right: 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tenant info card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.accentColor.withOpacity(0.08),
                                  AppTheme.accentColor.withOpacity(0.03),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusXL,
                              ),
                              border: Border.all(
                                color: AppTheme.accentColor.withOpacity(0.15),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Tenant header
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.primaryGradient,
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.radiusLG,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.person_rounded,
                                        size: 24,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Tenant Details',
                                            style: AppTheme
                                                .textTheme
                                                .labelMedium
                                                ?.copyWith(
                                                  color: AppTheme.textHint,
                                                  fontSize: 11,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            enquiry.user?.name ??
                                                'Unknown User',
                                            style: AppTheme.textTheme.titleLarge
                                                ?.copyWith(fontSize: 18),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                // Property info
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentColor.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.radiusMD,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.business_rounded,
                                        size: 20,
                                        color: AppTheme.accentColor,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Property',
                                            style: AppTheme
                                                .textTheme
                                                .labelMedium
                                                ?.copyWith(
                                                  color: AppTheme.textHint,
                                                  fontSize: 11,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            enquiry.pg?.name ?? 'Unknown PG',
                                            style:
                                                AppTheme.textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // Contact info
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.backgroundLight,
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusLG,
                                    ),
                                    border: Border.all(
                                      color: AppTheme.surfaceBorder,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppTheme.accentColor
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            AppTheme.radiusSM,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.contact_phone_rounded,
                                          size: 16,
                                          color: AppTheme.accentColor,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          enquiry.user?.mobNo1 ??
                                              enquiry.user?.email ??
                                              'No contact info',
                                          style: AppTheme.textTheme.bodySmall,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: const Text(
                                                'Copied to clipboard',
                                              ),
                                              backgroundColor: AppTheme.success,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      AppTheme.radiusMD,
                                                    ),
                                              ),
                                            ),
                                          );
                                        },
                                        child: Icon(
                                          Icons.copy_rounded,
                                          size: 16,
                                          color: AppTheme.textHint,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Status selection
                          Text(
                            'Select Status',
                            style: AppTheme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 12),

                          // Horizontal scrollable status chips
                          SizedBox(
                            height: 60,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: statuses.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final status = statuses[index];
                                final config = statusConfig[status]!;
                                final isSelected = selectedStatus == status;

                                return GestureDetector(
                                  onTap: () => setModalState(
                                    () => selectedStatus = status,
                                  ),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: isSelected
                                          ? LinearGradient(
                                              colors: config['gradient'],
                                            )
                                          : null,
                                      color: isSelected
                                          ? null
                                          : AppTheme.backgroundLight,
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusCircular,
                                      ),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.transparent
                                            : AppTheme.surfaceBorder,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          config['icon'],
                                          size: 18,
                                          color: isSelected
                                              ? Colors.white
                                              : config['color'],
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          config['label'],
                                          style: AppTheme.textTheme.labelLarge
                                              ?.copyWith(
                                                color: isSelected
                                                    ? Colors.white
                                                    : AppTheme.textSecondary,
                                                fontSize: 13,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Animated status preview
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  (statusConfig[selectedStatus]!['color']
                                          as Color)
                                      .withOpacity(0.1),
                                  (statusConfig[selectedStatus]!['color']
                                          as Color)
                                      .withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusLG,
                              ),
                              border: Border.all(
                                color:
                                    (statusConfig[selectedStatus]!['color']
                                            as Color)
                                        .withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors:
                                          statusConfig[selectedStatus]!['gradient'],
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusMD,
                                    ),
                                  ),
                                  child: Icon(
                                    statusConfig[selectedStatus]!['icon'],
                                    size: 22,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'New Status',
                                        style: AppTheme.textTheme.labelMedium
                                            ?.copyWith(
                                              color: AppTheme.textHint,
                                              fontSize: 11,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        statusConfig[selectedStatus]!['label'],
                                        style: AppTheme.textTheme.titleMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 20,
                                  color: statusConfig[selectedStatus]!['color'],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Remarks section
                          Text(
                            'Staff Remarks',
                            style: AppTheme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundLight,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusLG,
                              ),
                              border: Border.all(color: AppTheme.surfaceBorder),
                            ),
                            child: TextField(
                              controller: remarksController,
                              maxLines: 3,
                              style: AppTheme.textTheme.bodyMedium,
                              decoration: InputDecoration(
                                hintText: 'Add notes about this enquiry...',
                                hintStyle: AppTheme.textTheme.bodyMedium
                                    ?.copyWith(color: AppTheme.textHint),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(16),
                                suffixIcon: Align(
                                  widthFactor: 1.0,
                                  heightFactor: 1.0,
                                  alignment: Alignment.bottomRight,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentColor.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.radiusSM,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.edit_note_rounded,
                                        color: AppTheme.accentColor,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Character count
                          Padding(
                            padding: const EdgeInsets.only(top: 8, left: 12),
                            child: Text(
                              '${remarksController.text.length}/500 characters',
                              style: AppTheme.textTheme.labelSmall,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Action buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: isSaving
                                    ? null
                                    : () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusLG,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: AppTheme.textTheme.labelLarge
                                      ?.copyWith(color: AppTheme.textSecondary),
                                ),
                              ),
                              const SizedBox(width: 12),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                child: ElevatedButton(
                                  onPressed: isSaving
                                      ? null
                                      : () async {
                                          setModalState(() => isSaving = true);
                                          try {
                                            final repo = ref.read(
                                              enquiriesRepositoryProvider,
                                            );
                                            await repo
                                                .updateEnquiry(enquiry.id, {
                                                  'status': selectedStatus,
                                                  'staffRemarks':
                                                      remarksController.text
                                                          .trim(),
                                                });
                                            if (mounted) {
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Row(
                                                    children: [
                                                      const Icon(
                                                        Icons
                                                            .check_circle_rounded,
                                                        color: Colors.white,
                                                        size: 20,
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Text(
                                                          'Enquiry updated successfully',
                                                          style: AppTheme
                                                              .textTheme
                                                              .bodyMedium
                                                              ?.copyWith(
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  backgroundColor:
                                                      AppTheme.success,
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          AppTheme.radiusMD,
                                                        ),
                                                  ),
                                                ),
                                              );
                                              setState(() {
                                                _currentPage = 1;
                                                _hasMoreData = true;
                                              });
                                              ref.refresh(
                                                paginatedEnquiriesProvider(
                                                  1,
                                                ).future,
                                              );
                                            }
                                          } catch (e) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Row(
                                                    children: [
                                                      const Icon(
                                                        Icons
                                                            .error_outline_rounded,
                                                        color: Colors.white,
                                                        size: 20,
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Text(
                                                          e.toString(),
                                                          style: AppTheme
                                                              .textTheme
                                                              .bodyMedium
                                                              ?.copyWith(
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  backgroundColor:
                                                      AppTheme.error,
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          AppTheme.radiusMD,
                                                        ),
                                                  ),
                                                ),
                                              );
                                            }
                                            setModalState(
                                              () => isSaving = false,
                                            );
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        statusConfig[selectedStatus]!['color'],
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 28,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusLG,
                                      ),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: isSaving
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Save Changes',
                                              style: AppTheme
                                                  .textTheme
                                                  .labelLarge
                                                  ?.copyWith(
                                                    color: Colors.white,
                                                  ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 18,
                                              color: Colors.white,
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32), // Bottom padding
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
