import '../theme/app_colors.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/drive_sync_service.dart';
import '../services/hive_backup_service.dart';
import '../services/local_storage_backup_service.dart';
import '../widgets/custom_toast.dart';

class BackupScreen extends StatefulWidget {
  final VoidCallback? onGoToHome;

  const BackupScreen({super.key, this.onGoToHome});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Hisaab+ OLED Aesthetics
  static const Color greenAccent = Color(0xFF00E676);
  static const Color redAccent = Color(0xFFFF5252);
  static const Color blueAccent = Color(0xFF38BDF8);
  static const Color amberAccent = Color(0xFFFACC15);
  static const Color textMuted = Color(0xFFA1A1AA);
  static const Color textMutedDark = Color(0xFF71717A);

  bool _isLoading = false;
  String? _loadingStatus;
  List<DriveBackupFileItem> _cloudFiles = [];

  @override
  void initState() {
    super.initState();
    DriveSyncService.instance.initialize().then((_) {
      if (DriveSyncService.instance.isAuthenticated) {
        _fetchCloudHistory();
      }
    });

    DriveSyncService.instance.currentUserNotifier.addListener(_onUserChanged);
  }

  void _onUserChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    DriveSyncService.instance.currentUserNotifier.removeListener(_onUserChanged);
    super.dispose();
  }

  // ==========================================
  // CLOUD LOGIC
  // ==========================================

  Future<void> _fetchCloudHistory() async {
    if (!DriveSyncService.instance.isAuthenticated) return;
    try {
      setState(() {
        _isLoading = true;
        _loadingStatus = "Checking Drive backups...";
      });
      final list = await DriveSyncService.instance.fetchHisaabBackups();
      if (mounted) {
        setState(() {
          _cloudFiles = list;
          _isLoading = false;
          _loadingStatus = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingStatus = null;
        });
        AppToast.show(
          context,
          title: "Drive check failed: $e",
          type: ToastType.error,
        );
      }
    }
  }

  // Google Sign In
  Future<void> _handleGoogleSignIn() async {
    try {
      setState(() {
        _isLoading = true;
        _loadingStatus = "Connecting Google Drive...";
      });
      final account = await DriveSyncService.instance.signIn();
      if (account != null && mounted) {
        AppToast.show(
          context,
          title: "Drive connected: ${account.email}",
          type: ToastType.success,
        );
        await _fetchCloudHistory();
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          title: "Sign in failed: $e",
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingStatus = null;
        });
      }
    }
  }

  // Google Sign Out
  Future<void> _handleGoogleSignOut() async {
    await DriveSyncService.instance.signOut();
    setState(() {
      _cloudFiles = [];
    });
    if (mounted) {
      AppToast.show(
        context,
        title: "Signed out from Google Drive",
        type: ToastType.success,
      );
    }
  }

  // Local Storage: Export
  Future<void> _handleLocalExport() async {
    try {
      setState(() {
        _isLoading = true;
        _loadingStatus = "Creating local backup...";
      });
      await LocalStorageBackupService.instance.exportAndShareBackup();
      if (mounted) {
        AppToast.show(
          context,
          title: "Backup exported to local storage!",
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          title: "Local export failed: $e",
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingStatus = null;
        });
      }
    }
  }

  // Local Storage: Import
  Future<void> _handleLocalImport() async {
    try {
      final data =
          await LocalStorageBackupService.instance.pickAndReadLocalBackup();
      if (data == null) return;

      if (!mounted) return;
      _showImportConfirmDialog(
        title: "Local Storage Backup",
        dateString: data["exportDate"]?.toString() ?? "Unknown date",
        onConfirm: () async {
          setState(() {
            _isLoading = true;
            _loadingStatus = "Restoring data to app...";
          });
          await HiveBackupService.instance.restoreAllBoxesFromMap(data);
          if (mounted) {
            setState(() {
              _isLoading = false;
              _loadingStatus = null;
            });
            AppToast.show(
              context,
              title: "Local backup restored successfully!",
              type: ToastType.success,
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          title: "Import failed: $e",
          type: ToastType.error,
        );
      }
    }
  }

  // Cloud: Upload to Drive
  Future<void> _handleCloudUpload() async {
    if (!DriveSyncService.instance.isAuthenticated) {
      await _handleGoogleSignIn();
      if (!DriveSyncService.instance.isAuthenticated) return;
    }

    try {
      setState(() {
        _isLoading = true;
        _loadingStatus = "Uploading to Google Drive...";
      });

      final jsonString = HiveBackupService.instance.exportAllBoxesToJson();
      final now = DateTime.now();
      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(now);
      final fileName = 'hisaab_plus_backup_$dateStr.json';

      await DriveSyncService.instance.uploadBackupFile(
        jsonString: jsonString,
        customFileName: fileName,
      );

      if (mounted) {
        AppToast.show(
          context,
          title: "Data uploaded to Google Drive!",
          type: ToastType.success,
        );
        await _fetchCloudHistory();
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          title: "Upload failed: $e",
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingStatus = null;
        });
      }
    }
  }

  // Cloud: Restore Specific File
  Future<void> _handleRestoreSpecificCloudFile(DriveBackupFileItem file) async {
    final dateStr =
        DateFormat.yMMMd().add_jm().format(file.modifiedTime.toLocal());
    _showImportConfirmDialog(
      title: "Google Drive (${file.name})",
      dateString: dateStr,
      onConfirm: () async {
        try {
          setState(() {
            _isLoading = true;
            _loadingStatus = "Downloading & restoring ${file.name}...";
          });

          final jsonString =
              await DriveSyncService.instance.downloadBackupFileString(file.id);
          final dynamic decoded = jsonDecode(jsonString);

          if (decoded is! Map<String, dynamic>) {
            throw Exception('Invalid cloud backup payload');
          }

          await HiveBackupService.instance.restoreAllBoxesFromMap(decoded);

          if (mounted) {
            AppToast.show(
              context,
              title: "Restored successfully from Google Drive!",
              type: ToastType.success,
            );
          }
        } catch (e) {
          if (mounted) {
            AppToast.show(
              context,
              title: "Restore failed: $e",
              type: ToastType.error,
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _loadingStatus = null;
            });
          }
        }
      },
    );
  }

  // Cloud: Full Restore from Latest Drive File
  Future<void> _handleCloudRestore() async {
    if (!DriveSyncService.instance.isAuthenticated) {
      await _handleGoogleSignIn();
      if (!DriveSyncService.instance.isAuthenticated) return;
    }

    if (_cloudFiles.isEmpty) {
      await _fetchCloudHistory();
    }

    if (_cloudFiles.isEmpty) {
      if (mounted) {
        AppToast.show(
          context,
          title: "No Hisaab+ backup files found in Drive",
          type: ToastType.error,
        );
      }
      return;
    }

    final latestFile = _cloudFiles.first;
    _handleRestoreSpecificCloudFile(latestFile);
  }

  // Cloud: SMART TWO-WAY DATA SYNC
  Future<void> _handleSmartDataSync() async {
    if (!DriveSyncService.instance.isAuthenticated) {
      await _handleGoogleSignIn();
      if (!DriveSyncService.instance.isAuthenticated) return;
    }

    try {
      setState(() {
        _isLoading = true;
        _loadingStatus = "Scanning app & Google Drive...";
      });

      // 1. Fetch latest Drive backups
      await _fetchCloudHistory();

      Map<String, dynamic> cloudData = {};
      String? targetFileId;

      if (_cloudFiles.isNotEmpty) {
        final latest = _cloudFiles.first;
        targetFileId = latest.id;
        final jsonStr = await DriveSyncService.instance
            .downloadBackupFileString(targetFileId);
        final dynamic decoded = jsonDecode(jsonStr);
        if (decoded is Map<String, dynamic>) {
          cloudData = decoded;
        }
      }

      setState(() {
        _loadingStatus = "Merging local and cloud records...";
      });

      // 2. Perform intelligent two-way merge
      final mergeOutput =
          await HiveBackupService.instance.smartSync(cloudData);
      final syncResult = mergeOutput.result;
      final mergedDataMap = mergeOutput.mergedData;

      setState(() {
        _loadingStatus = "Syncing merged dataset to Drive...";
      });

      // 3. Upload merged payload to Drive
      final mergedJson =
          const JsonEncoder.withIndent('  ').convert(mergedDataMap);
      final now = DateTime.now();
      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(now);
      final fileName = 'hisaab_plus_backup_$dateStr.json';

      await DriveSyncService.instance.uploadBackupFile(
        jsonString: mergedJson,
        customFileName: fileName,
      );

      await _fetchCloudHistory();

      if (mounted) {
        _showSyncSummaryDialog(syncResult);
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          title: "Smart Sync error: $e",
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingStatus = null;
        });
      }
    }
  }

  // Delete individual cloud backup
  Future<void> _handleDeleteCloudFile(DriveBackupFileItem file) async {
    try {
      await DriveSyncService.instance.deleteBackupFile(file.id);
      setState(() {
        _cloudFiles.removeWhere((f) => f.id == file.id);
      });
      if (mounted) {
        AppToast.show(
          context,
          title: "Backup deleted from Drive",
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          title: "Delete failed: $e",
          type: ToastType.error,
        );
      }
    }
  }

  // ==========================================
  // CONFIRMATION & SUMMARY DIALOGS
  // ==========================================

  void _showImportConfirmDialog({
    required String title,
    required String dateString,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16161A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: amberAccent, size: 22),
            SizedBox(width: 8),
            Text(
              "Restore Backup?",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Text(
          "Source: $title\nDate: $dateString\n\nRestoring will replace your current app entries with this backup. Continue?",
          style: const TextStyle(color: textMuted, fontSize: 13, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: greenAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Restore",
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showSyncSummaryDialog(SyncResult result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16161A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: blueAccent.withValues(alpha: 0.4)),
        ),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: blueAccent, size: 22),
            SizedBox(width: 8),
            Text(
              "Smart Sync Complete",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Your app and Google Drive are now 100% in sync with zero data loss!",
              style: TextStyle(color: Colors.white, fontSize: 12.5, height: 1.4),
            ),
            const SizedBox(height: 14),
            _buildSyncMetricRow(
              "Transactions downloaded:",
              "+${result.downloadedTransactions}",
              greenAccent,
            ),
            _buildSyncMetricRow(
              "Personal expenses downloaded:",
              "+${result.downloadedExpenses}",
              greenAccent,
            ),
            _buildSyncMetricRow(
              "Khata friends synchronized:",
              "${result.friendsMerged}",
              blueAccent,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: blueAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Done",
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncMetricRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: textMuted, fontSize: 12)),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MAIN BUILD METHOD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = DriveSyncService.instance.currentUser;
    final isConnected = user != null;
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Ambient Wallpaper Layer (Dark & Light Mode)
          Positioned.fill(
            child: Opacity(
              opacity: colors.isDark ? 0.35 : 0.30,
              child: Image.asset(
                'assets/images/personal_kharcha_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),

          // 2. Ambient Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: colors.isDark
                      ? [
                          Colors.black.withValues(alpha: 0.38),
                          Colors.black.withValues(alpha: 0.72),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.40),
                          Colors.white.withValues(alpha: 0.60),
                          const Color(0xFFF8FAFC).withValues(alpha: 0.85),
                        ],
                  stops: const [0.0, 0.40, 1.0],
                ),
              ),
            ),
          ),

          // 3. Foreground Content
          SafeArea(
            child: Column(
              children: [
                // Top Custom Header
                _buildHeader(context, isConnected),

                // Main Scrollable Cards
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    children: [
                      // Loading Status Pill
                      if (_isLoading && _loadingStatus != null) ...[
                        _buildLoadingStatusBar(),
                        const SizedBox(height: 12),
                      ],

                      // 1. CARD 1: GOOGLE DRIVE CLOUD & HISTORY
                      _buildCard1GoogleDrive(isConnected, user),

                      const SizedBox(height: 14),

                      // 2. CARD 2: LOCAL STORAGE FILE MANAGEMENT
                      _buildCard2LocalStorage(),

                      const SizedBox(height: 14),

                      // 3. CARD 3: CLOUD SYNC & SMART MERGE
                      _buildCard3CloudAndSmartSync(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HEADER
  // ==========================================

  Widget _buildHeader(BuildContext context, bool isConnected) {
    final bool canPop = Navigator.of(context).canPop();

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 16, 8),
      child: Row(
        children: [
          if (canPop)
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white70,
                size: 18,
              ),
              onPressed: () => Navigator.of(context).pop(),
            )
          else if (widget.onGoToHome != null)
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white70,
                size: 18,
              ),
              onPressed: widget.onGoToHome,
            )
          else
            Container(
              margin: const EdgeInsets.only(left: 6, right: 8),
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_sync_rounded,
                color: greenAccent,
                size: 18,
              ),
            ),
          const SizedBox(width: 4),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    "DATA",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    "& SYNC",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: greenAccent,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Text(
                "Google Drive & local vault",
                style: TextStyle(
                  fontSize: 11,
                  color: textMuted,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Live Connection Status Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: (isConnected ? greenAccent : Colors.grey)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (isConnected ? greenAccent : Colors.grey)
                    .withValues(alpha: 0.28),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isConnected ? greenAccent : Colors.grey,
                    shape: BoxShape.circle,
                    boxShadow: isConnected
                        ? [
                            BoxShadow(
                              color: greenAccent.withValues(alpha: 0.6),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isConnected ? "Connected" : "Offline",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isConnected ? greenAccent : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Loading Status Bar
  Widget _buildLoadingStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: blueAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: blueAccent.withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: blueAccent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _loadingStatus!,
              style: const TextStyle(
                color: blueAccent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CARD 1: GOOGLE DRIVE CLOUD & HISTORY
  // ==========================================

  Widget _buildCard1GoogleDrive(bool isConnected, dynamic user) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: blueAccent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: blueAccent.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Icon(
                      Icons.cloud_outlined,
                      color: blueAccent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Google Drive Cloud",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          "Stores only Hisaab+ backup files in private cloud",
                          style: TextStyle(color: textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  if (isConnected)
                    IconButton(
                      icon: const Icon(
                        Icons.logout_rounded,
                        size: 17,
                        color: redAccent,
                      ),
                      tooltip: "Disconnect Drive",
                      onPressed: _handleGoogleSignOut,
                    ),
                ],
              ),

              const SizedBox(height: 14),

              // Connected Profile or Sign In CTA
              if (isConnected) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: blueAccent,
                        backgroundImage: user?.photoUrl != null
                            ? NetworkImage(user!.photoUrl!)
                            : null,
                        child: user?.photoUrl == null
                            ? Text(
                                (user?.displayName?[0] ?? 'G').toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? "Google Account",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              user?.email ?? "",
                              style: const TextStyle(
                                color: textMuted,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: greenAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: greenAccent,
                              size: 13,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "Active",
                              style: TextStyle(
                                color: greenAccent,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    icon: const Icon(Icons.add_to_drive_rounded, size: 18),
                    label: const Text(
                      "Connect Google Drive",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blueAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Cloud History Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        "Drive Backup History",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (isConnected && _cloudFiles.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "${_cloudFiles.length}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (isConnected)
                    InkWell(
                      onTap: _fetchCloudHistory,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.refresh_rounded,
                              size: 13,
                              color: textMuted,
                            ),
                            SizedBox(width: 3),
                            Text(
                              "Refresh",
                              style: TextStyle(
                                color: textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 10),

              // History List Items
              if (!isConnected)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  child: const Text(
                    "Connect your Google Drive above to see your stored backups.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textMutedDark, fontSize: 11.5),
                  ),
                )
              else if (_cloudFiles.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  child: const Text(
                    "No Hisaab+ backups in Drive yet.\nTap 'Upload to Drive' or 'Smart Sync' below to back up!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 11.5,
                      height: 1.45,
                    ),
                  ),
                )
              else
                ..._cloudFiles.map((file) => _buildCloudFileTile(file)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCloudFileTile(DriveBackupFileItem file) {
    final dateStr =
        DateFormat.yMMMd().add_jm().format(file.modifiedTime.toLocal());

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: greenAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.cloud_done_rounded,
              color: greenAccent,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  "$dateStr • ${file.formattedSize}",
                  style: const TextStyle(color: textMuted, fontSize: 10.5),
                ),
              ],
            ),
          ),
          // Restore this specific backup
          IconButton(
            icon: const Icon(
              Icons.restore_rounded,
              color: blueAccent,
              size: 18,
            ),
            onPressed: () => _handleRestoreSpecificCloudFile(file),
            tooltip: "Restore this backup",
          ),
          // Delete from Drive
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: redAccent,
              size: 18,
            ),
            onPressed: () => _handleDeleteCloudFile(file),
            tooltip: "Delete from Drive",
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CARD 2: LOCAL STORAGE FILE MANAGEMENT
  // ==========================================

  Widget _buildCard2LocalStorage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: greenAccent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: greenAccent.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Icon(
                      Icons.folder_open_rounded,
                      color: greenAccent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Local Data Management",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          "Export & import files offline on your phone memory",
                          style: TextStyle(color: textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Export / Import Buttons
              Row(
                children: [
                  // 1. Download to Local Storage
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleLocalExport,
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text(
                        "Download File",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // 2. Import from Local Storage
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _handleLocalImport,
                      icon: const Icon(Icons.file_open_rounded, size: 16),
                      label: const Text(
                        "Import File",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              const Row(
                children: [
                  Icon(
                    Icons.security_rounded,
                    size: 12,
                    color: textMutedDark,
                  ),
                  SizedBox(width: 6),
                  Text(
                    "100% offline & private • Encrypted on your device",
                    style: TextStyle(
                      color: textMutedDark,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // CARD 3: CLOUD SYNC & SMART MERGE
  // ==========================================

  Widget _buildCard3CloudAndSmartSync() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: amberAccent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: amberAccent.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Icon(
                      Icons.sync_rounded,
                      color: amberAccent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Cloud Sync & Actions",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          "Manual cloud controls & two-way smart sync",
                          style: TextStyle(color: textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Upload to Drive & Restore Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _handleCloudUpload,
                      icon: const Icon(Icons.cloud_upload_rounded, size: 16),
                      label: const Text(
                        "Upload to Drive",
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleCloudRestore,
                      icon: const Icon(Icons.cloud_download_rounded, size: 16),
                      label: const Text(
                        "Restore Latest",
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ==========================================
              // SMART TWO-WAY DATA SYNC HERO BANNER
              // ==========================================
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      blueAccent.withValues(alpha: 0.14),
                      greenAccent.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: blueAccent.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: blueAccent.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                color: blueAccent,
                                size: 13,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "SMART MERGE",
                                style: TextStyle(
                                  color: blueAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "⚡ Smart Two-Way Data Sync",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Dual-scan system: simultaneously inspects both your phone storage and Google Drive. Missing cloud records are merged into your phone, and missing local entries are uploaded to Drive without deleting anything.",
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 11.5,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _handleSmartDataSync,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Icon(Icons.sync_rounded, size: 18),
                        label: const Text(
                          "Run Smart Two-Way Sync",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: blueAccent,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
