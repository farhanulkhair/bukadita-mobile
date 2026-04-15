import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/theme.dart';
import '../../services/storage_service.dart';
import '../../services/notification_service.dart';

/// Resizable Navbar Component dengan scroll detection
/// Navbar akan mengecil dan berubah style saat user scroll
class ResizableNavbar extends StatefulWidget {
  final ScrollController? scrollController;
  final String? activeSection;
  final Function(String)? onNavigate;

  const ResizableNavbar({
    super.key,
    this.scrollController,
    this.activeSection,
    this.onNavigate,
  });

  @override
  State<ResizableNavbar> createState() => _ResizableNavbarState();
}

class _ResizableNavbarState extends State<ResizableNavbar>
    with SingleTickerProviderStateMixin {
  bool _isScrolled = false;
  bool _isVisible = true;
  double _lastScrollPosition = 0;
  final StorageService _storageService = StorageService();
  bool _isLoggedIn = false;

  late AnimationController _animationController;
  late Animation<double> _heightAnimation;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _setupAnimations();
    _setupScrollListener();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _heightAnimation = Tween<double>(begin: 64.0, end: 56.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void _setupScrollListener() {
    widget.scrollController?.addListener(_handleScroll);
  }

  void _handleScroll() {
    final currentScroll = widget.scrollController?.offset ?? 0;

    // Update scroll state
    if (currentScroll > 10 && !_isScrolled) {
      setState(() => _isScrolled = true);
      _animationController.forward();
    } else if (currentScroll <= 10 && _isScrolled) {
      setState(() => _isScrolled = false);
      _animationController.reverse();
    }

    // Handle navbar visibility (hide on scroll down, show on scroll up)
    if ((currentScroll - _lastScrollPosition).abs() > 5) {
      if (currentScroll > _lastScrollPosition && currentScroll > 100) {
        // Scrolling down
        if (_isVisible) {
          setState(() => _isVisible = false);
        }
      } else {
        // Scrolling up
        if (!_isVisible) {
          setState(() => _isVisible = true);
        }
      }
      _lastScrollPosition = currentScroll;
    }
  }

  Future<void> _checkLoginStatus() async {
    final loggedIn = await _storageService.isLoggedIn();
    if (mounted) {
      setState(() => _isLoggedIn = loggedIn);
    }
  }

  Future<void> _handleLogout() async {
    await _storageService.clearAll();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 300),
      offset: _isVisible ? Offset.zero : const Offset(0, -1),
      curve: Curves.easeInOut,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            margin: EdgeInsets.only(
              top: _isScrolled ? 8 : 0,
              left: _isScrolled ? 16 : 0,
              right: _isScrolled ? 16 : 0,
            ),
            decoration: BoxDecoration(
              color:
                  _isScrolled
                      ? AppColors.secondary.withOpacity(0.95)
                      : AppColors.white, // Ubah dari transparent ke white
              borderRadius: BorderRadius.circular(_isScrolled ? 24 : 0),
              border:
                  _isScrolled
                      ? Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      )
                      : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isScrolled ? 0.1 : 0.05),
                  blurRadius: _isScrolled ? 20 : 8,
                  offset: Offset(0, _isScrolled ? 4 : 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_isScrolled ? 24 : 0),
              child: BackdropFilter(
                filter:
                    _isScrolled
                        ? ColorFilter.mode(
                          Colors.white.withOpacity(0.1),
                          BlendMode.srcOver,
                        )
                        : ColorFilter.mode(Colors.transparent, BlendMode.src),
                child: Container(
                  height: _heightAnimation.value,
                  padding: EdgeInsets.symmetric(
                    horizontal:
                        _isScrolled
                            ? (isTablet ? 24 : 16)
                            : (isTablet ? 32 : 16),
                  ),
                  child: Row(
                    children: [
                      // Logo Section
                      _buildLogo(),

                      const Spacer(),

                      // Action Buttons
                      _buildActionButtons(isTablet),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedScale(
      duration: const Duration(milliseconds: 200),
      scale: _isScrolled ? 0.9 : 1.0,
      child: GestureDetector(
        onTap: () {
          widget.scrollController?.animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo Icon
            Container(
              width: _isScrolled ? 36 : 40,
              height: _isScrolled ? 36 : 40,
              decoration: BoxDecoration(
                color: _isScrolled ? AppColors.white : AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.menu_book_rounded,
                color: _isScrolled ? AppColors.primary : AppColors.white,
                size: _isScrolled ? 20 : 24,
              ),
            ),
            const SizedBox(width: 12),
            // Logo Text
            Text(
              'BukaDita',
              style: AppTextStyles.heading.copyWith(
                color: _isScrolled ? AppColors.white : AppColors.primary,
                fontSize: _isScrolled ? 18 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isTablet) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isLoggedIn) ...[
          ValueListenableBuilder<int>(
            valueListenable: NotificationService().unreadCount,
            builder: (context, count, _) {
              return IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      color: _isScrolled ? AppColors.white : AppColors.primary,
                      size: 22,
                    ),
                    if (count > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(1.5),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _isScrolled ? AppColors.secondary : AppColors.white,
                              width: 1.5,
                            ),
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            count > 99 ? '99+' : '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () async {
                  await Navigator.pushNamed(context, '/notifications');
                  NotificationService().refreshCount();
                },
              );
            },
          ),
          const SizedBox(width: 4),
          // Profile/Menu Button
          PopupMenuButton<String>(
            icon: Icon(
              Icons.person_outline,
              color: _isScrolled ? AppColors.white : AppColors.primary,
              size: 22,
            ),
            color: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) async {
              if (value == 'profile') {
                Navigator.pushNamed(context, '/user/profil');
              } else if (value == 'logout') {
                await _handleLogout();
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, size: 18),
                        const SizedBox(width: 12),
                        Text('Profil', style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 18, color: AppColors.error),
                        const SizedBox(width: 12),
                        Text(
                          'Keluar',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
          ),
        ] else ...[
          // Login Button
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
            style: TextButton.styleFrom(
              foregroundColor:
                  _isScrolled ? AppColors.white : AppColors.primary,
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 20 : 16,
                vertical: 8,
              ),
            ),
            child: Text(
              'Masuk',
              style: AppTextStyles.labelMedium.copyWith(
                color: _isScrolled ? AppColors.white : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Bottom Navigation Bar untuk navigasi antar halaman utama
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_outlined,
                label: 'Beranda',
                index: 0,
                isActive: currentIndex == 0,
              ),
              _buildNavItem(
                icon: Icons.menu_book_outlined,
                label: 'Modul',
                index: 1,
                isActive: currentIndex == 1,
              ),
              _buildNavItem(
                icon: Icons.person_outline,
                label: 'Profil',
                index: 2,
                isActive: currentIndex == 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isActive,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color:
                isActive
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive ? AppColors.primary : AppColors.gray500,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isActive ? AppColors.primary : AppColors.gray500,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
