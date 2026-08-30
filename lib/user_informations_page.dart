import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/settings_option_page.dart';
import 'widgets/glift_loader.dart';

class UserInformationsPage extends StatefulWidget {
  final SupabaseClient supabase;

  const UserInformationsPage({
    super.key,
    required this.supabase,
  });

  @override
  State<UserInformationsPage> createState() => _UserInformationsPageState();
}

class _UserInformationsPageState extends State<UserInformationsPage> {
  bool _isLoading = true;

  String? _gender;
  String? _name;
  String? _birthDate;
  String? _email;
  String? _country;
  String? _experience;
  String? _mainGoal;
  String? _trainingPlace;
  String? _weeklySessions;
  String? _supplements;

  late final TextEditingController _nameController;
  late final FocusNode _nameFocusNode;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _nameFocusNode = FocusNode();
    _nameFocusNode.addListener(() {
      if (!_nameFocusNode.hasFocus) {
        _saveName();
      }
    });

    _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    final user = widget.supabase.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    _email = user.email;

    try {
      final response = await widget.supabase
          .from('profiles')
          .select('name, gender, birth_date, country, experience, main_goal, training_place, weekly_sessions, supplements')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _name = response['name'] as String?;
          _nameController.text = _name ?? '';
          _gender = response['gender'] as String?;
          _birthDate = response['birth_date'] as String?;
          _country = response['country'] as String?;
          _experience = response['experience'] as String?;
          _mainGoal = response['main_goal'] as String?;
          _trainingPlace = response['training_place'] as String?;
          _weeklySessions = response['weekly_sessions'] as String?;
          _supplements = response['supplements'] as String?;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _saveName() {
    final newName = _nameController.text.trim();
    if (newName != (_name ?? '')) {
      _name = newName;
      _updateProfileField('name', newName.isEmpty ? null : newName);
    }
  }

  void _showCupertinoDatePicker() {
    DateTime initial = DateTime(1995, 1, 1);
    if (_birthDate != null && _birthDate!.isNotEmpty) {
      try {
        initial = DateTime.parse(_birthDate!);
      } catch (_) {}
    }

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 280,
          decoration: const BoxDecoration(
            color: Color(0xFFF2F2F7),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: CupertinoTheme(
              data: const CupertinoThemeData(
                brightness: Brightness.light,
              ),
              child: Localizations.override(
                context: context,
                locale: const Locale('fr', 'FR'),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  dateOrder: DatePickerDateOrder.dmy,
                  initialDateTime: initial,
                  minimumDate: DateTime(1920, 1, 1),
                  maximumDate: DateTime.now(),
                  onDateTimeChanged: (DateTime newDate) {
                    final formatted = DateFormat('yyyy-MM-dd').format(newDate);
                    setState(() {
                      _birthDate = formatted;
                    });
                    _updateProfileField('birth_date', formatted);
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateProfileField(String column, dynamic value) async {
    final userId = widget.supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await widget.supabase.from('profiles').upsert({
        'id': userId,
        column: value,
      });
    } catch (e) {
      debugPrint('Error updating profile field $column: $e');
    }
  }

  String _formatBirthDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Non spécifié';
    try {
      final parts = raw.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
      final dt = DateTime.parse(raw);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }

  String? _getGenderIcon(String? gender) {
    if (gender == null || gender.trim().isEmpty) return null;
    switch (gender.trim().toLowerCase()) {
      case 'homme':
        return 'assets/icons/homme.svg';
      case 'femme':
        return 'assets/icons/femme.svg';
      default:
        return null;
    }
  }

  String? _getCountryFlag(String? country) {
    if (country == null || country.trim().isEmpty) return null;
    switch (country.trim().toLowerCase()) {
      case 'france':
        return 'assets/icons/flags/france.svg';
      case 'belgique':
        return 'assets/icons/flags/belgique.svg';
      case 'suisse':
        return 'assets/icons/flags/suisse.svg';
      case 'canada':
        return 'assets/icons/flags/canada.svg';
      case 'autre':
        return 'assets/icons/flags/autre.svg';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _SettingsBackButton(onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Réglages',
                        style: GoogleFonts.quicksand(
                          color: const Color(0xFF3A416F),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mes informations',
                        style: GoogleFonts.quicksand(
                          color: const Color(0xFF3A416F),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content List
            Expanded(
              child: _isLoading
                  ? const GliftLoader(size: 32)
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        20,
                        0,
                        20,
                        MediaQuery.of(context).padding.bottom + 40,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFECE9F1)),
                        ),
                        child: Column(
                          children: [
                            // 1. Genre
                            _InfoTile(
                              title: 'Genre',
                              value: (_gender == null || _gender!.isEmpty)
                                  ? 'Non spécifié'
                                    : _gender!,
                                flagIconPath: _getGenderIcon(_gender),
                                showArrow: true,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => SettingsOptionPage(
                                        headerTitle: 'Mes informations',
                                        headerSubtitle: 'Genre',
                                        options: const [
                                          SettingsOptionItem(value: '', label: 'Non spécifié'),
                                          SettingsOptionItem(
                                            value: 'Homme',
                                            label: 'Homme',
                                            iconPath: 'assets/icons/homme.svg',
                                          ),
                                          SettingsOptionItem(
                                            value: 'Femme',
                                            label: 'Femme',
                                            iconPath: 'assets/icons/femme.svg',
                                          ),
                                        ],
                                        initialValue: _gender ?? '',
                                        onChanged: (val) {
                                          final finalVal = val.isEmpty ? null : val;
                                          setState(() => _gender = finalVal);
                                          _updateProfileField('gender', finalVal);
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // 2. Prénom (Inline text editing)
                              _EditableTextTile(
                                title: 'Prénom',
                                controller: _nameController,
                                focusNode: _nameFocusNode,
                                hintText: 'Non spécifié',
                                onSubmitted: (_) {
                                  _saveName();
                                  _nameFocusNode.unfocus();
                                },
                              ),

                              // 3. Date de naissance (Cupertino native wheel picker)
                              _InfoTile(
                                title: 'Date de naissance',
                                value: _formatBirthDate(_birthDate),
                                showArrow: false,
                                onTap: _showCupertinoDatePicker,
                              ),

                              // 4. Email (read-only)
                              _InfoTile(
                                title: 'Email',
                                value: _email ?? '',
                                showArrow: false,
                                isMuted: true,
                              ),

                              // 5. Pays de résidence (With flags)
                              _InfoTile(
                                title: 'Pays de résidence',
                                value: (_country == null || _country!.isEmpty)
                                    ? 'Non spécifié'
                                    : _country!,
                                flagIconPath: _getCountryFlag(_country),
                                showArrow: true,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => SettingsOptionPage(
                                        headerTitle: 'Mes informations',
                                        headerSubtitle: 'Pays de résidence',
                                        options: const [
                                          SettingsOptionItem(value: '', label: 'Non spécifié'),
                                          SettingsOptionItem(
                                            value: 'Autre',
                                            label: 'Autre',
                                            iconPath: 'assets/icons/flags/autre.svg',
                                          ),
                                          SettingsOptionItem(
                                            value: 'Belgique',
                                            label: 'Belgique',
                                            iconPath: 'assets/icons/flags/belgique.svg',
                                          ),
                                          SettingsOptionItem(
                                            value: 'Canada',
                                            label: 'Canada',
                                            iconPath: 'assets/icons/flags/canada.svg',
                                          ),
                                          SettingsOptionItem(
                                            value: 'France',
                                            label: 'France',
                                            iconPath: 'assets/icons/flags/france.svg',
                                          ),
                                          SettingsOptionItem(
                                            value: 'Suisse',
                                            label: 'Suisse',
                                            iconPath: 'assets/icons/flags/suisse.svg',
                                          ),
                                        ],
                                        initialValue: _country ?? '',
                                        onChanged: (val) {
                                          final finalVal = val.isEmpty ? null : val;
                                          setState(() => _country = finalVal);
                                          _updateProfileField('country', finalVal);
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // 6. Années de pratique
                              _InfoTile(
                                title: 'Années de pratique',
                                value: (_experience == null || _experience!.isEmpty)
                                    ? 'Non spécifié'
                                    : _experience!,
                                showArrow: true,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => SettingsOptionPage(
                                        headerTitle: 'Mes informations',
                                        headerSubtitle: 'Années de pratique',
                                        options: const [
                                          SettingsOptionItem(value: '', label: 'Non spécifié'),
                                          SettingsOptionItem(value: '0', label: '0'),
                                          SettingsOptionItem(value: '1', label: '1'),
                                          SettingsOptionItem(value: '2', label: '2'),
                                          SettingsOptionItem(value: '3', label: '3'),
                                          SettingsOptionItem(value: '4', label: '4'),
                                          SettingsOptionItem(value: '5+', label: '5+'),
                                        ],
                                        initialValue: _experience ?? '',
                                        onChanged: (val) {
                                          final finalVal = val.isEmpty ? null : val;
                                          setState(() => _experience = finalVal);
                                          _updateProfileField('experience', finalVal);
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // 7. Objectif principal
                              _InfoTile(
                                title: 'Objectif principal',
                                value: (_mainGoal == null || _mainGoal!.isEmpty)
                                    ? 'Non spécifié'
                                    : _mainGoal!,
                                showArrow: true,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => SettingsOptionPage(
                                        headerTitle: 'Mes informations',
                                        headerSubtitle: 'Objectif principal',
                                        options: const [
                                          SettingsOptionItem(value: '', label: 'Non spécifié'),
                                          SettingsOptionItem(value: 'Prise de muscle', label: 'Prise de muscle'),
                                          SettingsOptionItem(value: 'Perte de graisse', label: 'Perte de graisse'),
                                          SettingsOptionItem(value: 'Perte de poids', label: 'Perte de poids'),
                                          SettingsOptionItem(value: 'Gain de force', label: 'Gain de force'),
                                          SettingsOptionItem(value: 'Performance sportive', label: 'Performance sportive'),
                                          SettingsOptionItem(value: 'Performance', label: 'Performance'),
                                          SettingsOptionItem(value: 'Confiance & bien-être', label: 'Confiance & bien-être'),
                                          SettingsOptionItem(value: 'Prévention des blessures', label: 'Prévention des blessures'),
                                          SettingsOptionItem(value: 'Santé & longévité', label: 'Santé & longévité'),
                                          SettingsOptionItem(value: 'Routine & discipline', label: 'Routine & discipline'),
                                          SettingsOptionItem(value: 'Remise en forme', label: 'Remise en forme'),
                                        ],
                                        initialValue: _mainGoal ?? '',
                                        onChanged: (val) {
                                          final finalVal = val.isEmpty ? null : val;
                                          setState(() => _mainGoal = finalVal);
                                          _updateProfileField('main_goal', finalVal);
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // 8. Lieu d’entraînement
                              _InfoTile(
                                title: 'Lieu d’entraînement',
                                value: (_trainingPlace == null || _trainingPlace!.isEmpty)
                                    ? 'Non spécifié'
                                    : _trainingPlace!,
                                showArrow: true,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => SettingsOptionPage(
                                        headerTitle: 'Mes informations',
                                        headerSubtitle: 'Lieu d’entraînement',
                                        options: const [
                                          SettingsOptionItem(value: '', label: 'Non spécifié'),
                                          SettingsOptionItem(value: 'Salle', label: 'Salle'),
                                          SettingsOptionItem(value: 'Domicile', label: 'Domicile'),
                                          SettingsOptionItem(value: 'Les deux', label: 'Les deux'),
                                        ],
                                        initialValue: _trainingPlace ?? '',
                                        onChanged: (val) {
                                          final finalVal = val.isEmpty ? null : val;
                                          setState(() => _trainingPlace = finalVal);
                                          _updateProfileField('training_place', finalVal);
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // 9. Séances par semaine
                              _InfoTile(
                                title: 'Séances par semaine',
                                value: (_weeklySessions == null || _weeklySessions!.isEmpty)
                                    ? 'Non spécifié'
                                    : _weeklySessions!,
                                showArrow: true,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => SettingsOptionPage(
                                        headerTitle: 'Mes informations',
                                        headerSubtitle: 'Séances par semaine',
                                        options: const [
                                          SettingsOptionItem(value: '', label: 'Non spécifié'),
                                          SettingsOptionItem(value: '1', label: '1'),
                                          SettingsOptionItem(value: '2', label: '2'),
                                          SettingsOptionItem(value: '3', label: '3'),
                                          SettingsOptionItem(value: '4', label: '4'),
                                          SettingsOptionItem(value: '5', label: '5'),
                                          SettingsOptionItem(value: '6+', label: '6+'),
                                        ],
                                        initialValue: _weeklySessions ?? '',
                                        onChanged: (val) {
                                          final finalVal = val.isEmpty ? null : val;
                                          setState(() => _weeklySessions = finalVal);
                                          _updateProfileField('weekly_sessions', finalVal);
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // 10. Compléments alimentaires
                              _InfoTile(
                                title: 'Compléments alimentaires',
                                value: (_supplements == null || _supplements!.isEmpty)
                                    ? 'Non spécifié'
                                    : _supplements!,
                                showArrow: true,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => SettingsOptionPage(
                                        headerTitle: 'Mes informations',
                                        headerSubtitle: 'Compléments alimentaires',
                                        options: const [
                                          SettingsOptionItem(value: '', label: 'Non spécifié'),
                                          SettingsOptionItem(value: 'Oui', label: 'Oui'),
                                          SettingsOptionItem(value: 'Non', label: 'Non'),
                                        ],
                                        initialValue: _supplements ?? '',
                                        onChanged: (val) {
                                          final finalVal = val.isEmpty ? null : val;
                                          setState(() => _supplements = finalVal);
                                          _updateProfileField('supplements', finalVal);
                                        },
                                      ),
                                    ),
                                  );
                                },
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
  }

class _SettingsBackButton extends StatelessWidget {
  const _SettingsBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: Color(0xFF3A416F),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.chevron_left,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String value;
  final String? flagIconPath;
  final bool showArrow;
  final bool isMuted;
  final VoidCallback? onTap;

  const _InfoTile({
    required this.title,
    required this.value,
    this.flagIconPath,
    this.showArrow = false,
    this.isMuted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: EdgeInsets.only(
          left: 15,
          right: showArrow ? 9 : 15,
        ),
        child: Row(
          children: [
            Text(
              title,
              style: GoogleFonts.quicksand(
                color: const Color(0xFF3A416F),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (flagIconPath != null) ...[
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: SvgPicture.asset(
                            flagIconPath!,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.quicksand(
                        color: isMuted
                            ? const Color(0xFFD7D4DC)
                            : const Color(0xFF5D6494),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (showArrow) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF5D6494),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditableTextTile extends StatefulWidget {
  final String title;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final ValueChanged<String>? onSubmitted;

  const _EditableTextTile({
    required this.title,
    required this.controller,
    required this.focusNode,
    this.hintText = 'Non spécifié',
    this.onSubmitted,
  });

  @override
  State<_EditableTextTile> createState() => _EditableTextTileState();
}

class _EditableTextTileState extends State<_EditableTextTile> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _isFocused = widget.focusNode.hasFocus;
    widget.focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChange);
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = widget.focusNode.hasFocus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text.trim();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        widget.focusNode.requestFocus();
      },
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(
          children: [
            Text(
              widget.title,
              style: GoogleFonts.quicksand(
                color: const Color(0xFF3A416F),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Stack(
                alignment: Alignment.centerRight,
                children: [
                  Opacity(
                    opacity: _isFocused ? 1.0 : 0.0,
                    child: TextField(
                      controller: widget.controller,
                      focusNode: widget.focusNode,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.quicksand(
                        color: const Color(0xFF5D6494),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: widget.hintText,
                        hintStyle: GoogleFonts.quicksand(
                          color: const Color(0xFFD7D4DC),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: widget.onSubmitted,
                    ),
                  ),
                  if (!_isFocused)
                    IgnorePointer(
                      child: Text(
                        text.isEmpty ? widget.hintText : text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.quicksand(
                          color: text.isEmpty
                              ? const Color(0xFFD7D4DC)
                              : const Color(0xFF5D6494),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
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
}
