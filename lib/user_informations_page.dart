import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase/supabase.dart';
import 'widgets/settings_option_page.dart';

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

  Future<void> _pickBirthDate() async {
    DateTime initialDate = DateTime(1995, 1, 1);
    if (_birthDate != null && _birthDate!.isNotEmpty) {
      try {
        initialDate = DateTime.parse(_birthDate!);
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF7069FA),
              onPrimary: Colors.white,
              onSurface: Color(0xFF3A416F),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF7069FA),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted = DateFormat('yyyy-MM-dd').format(picked);
      setState(() => _birthDate = formatted);
      _updateProfileField('birth_date', formatted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
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
              const SizedBox(height: 30),

              // Content List
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7069FA)),
                        ),
                      )
                    : SingleChildScrollView(
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
                                showArrow: true,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => SettingsOptionPage(
                                        headerTitle: 'Mes informations',
                                        headerSubtitle: 'Genre',
                                        options: const [
                                          SettingsOptionItem(value: '', label: 'Non spécifié'),
                                          SettingsOptionItem(value: 'Homme', label: 'Homme'),
                                          SettingsOptionItem(value: 'Femme', label: 'Femme'),
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

                              // 2. Prénom (Editable directly in place)
                              _EditableTextTile(
                                title: 'Prénom',
                                controller: _nameController,
                                focusNode: _nameFocusNode,
                                onSubmitted: (_) {
                                  _saveName();
                                  _nameFocusNode.unfocus();
                                },
                              ),

                              // 3. Date de naissance
                              _InfoTile(
                                title: 'Date de naissance',
                                value: _formatBirthDate(_birthDate),
                                showArrow: false,
                                onTap: _pickBirthDate,
                              ),

                              // 4. Email (read-only)
                              _InfoTile(
                                title: 'Email',
                                value: _email ?? '',
                                showArrow: false,
                                isMuted: true,
                              ),

                              // 5. Pays de résidence
                              _InfoTile(
                                title: 'Pays de résidence',
                                value: _country ?? 'Non spécifié',
                                showArrow: true,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => SettingsOptionPage(
                                        headerTitle: 'Mes informations',
                                        headerSubtitle: 'Pays de résidence',
                                        options: const [
                                          SettingsOptionItem(value: 'France', label: 'France'),
                                          SettingsOptionItem(value: 'Belgique', label: 'Belgique'),
                                          SettingsOptionItem(value: 'Suisse', label: 'Suisse'),
                                          SettingsOptionItem(value: 'Canada', label: 'Canada'),
                                          SettingsOptionItem(value: 'Autre', label: 'Autre'),
                                        ],
                                        initialValue: _country ?? '',
                                        onChanged: (val) {
                                          setState(() => _country = val);
                                          _updateProfileField('country', val);
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // 6. Années de pratique
                              _InfoTile(
                                title: 'Années de pratique',
                                value: _experience ?? 'Non spécifié',
                                showArrow: true,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => SettingsOptionPage(
                                        headerTitle: 'Mes informations',
                                        headerSubtitle: 'Années de pratique',
                                        options: const [
                                          SettingsOptionItem(value: '0', label: '0'),
                                          SettingsOptionItem(value: '1', label: '1'),
                                          SettingsOptionItem(value: '2', label: '2'),
                                          SettingsOptionItem(value: '3', label: '3'),
                                          SettingsOptionItem(value: '4', label: '4'),
                                          SettingsOptionItem(value: '5+', label: '5+'),
                                        ],
                                        initialValue: _experience ?? '',
                                        onChanged: (val) {
                                          setState(() => _experience = val);
                                          _updateProfileField('experience', val);
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // 7. Objectif principal
                              _InfoTile(
                                title: 'Objectif principal',
                                value: _mainGoal ?? 'Non spécifié',
                                showArrow: true,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => SettingsOptionPage(
                                        headerTitle: 'Mes informations',
                                        headerSubtitle: 'Objectif principal',
                                        options: const [
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
                                          setState(() => _mainGoal = val);
                                          _updateProfileField('main_goal', val);
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // 8. Lieu d’entraînement
                              _InfoTile(
                                title: 'Lieu d’entraînement',
                                value: _trainingPlace ?? 'Non spécifié',
                                showArrow: true,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => SettingsOptionPage(
                                        headerTitle: 'Mes informations',
                                        headerSubtitle: 'Lieu d’entraînement',
                                        options: const [
                                          SettingsOptionItem(value: 'Salle', label: 'Salle'),
                                          SettingsOptionItem(value: 'Domicile', label: 'Domicile'),
                                          SettingsOptionItem(value: 'Les deux', label: 'Les deux'),
                                        ],
                                        initialValue: _trainingPlace ?? '',
                                        onChanged: (val) {
                                          setState(() => _trainingPlace = val);
                                          _updateProfileField('training_place', val);
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // 9. Séances par semaine
                              _InfoTile(
                                title: 'Séances par semaine',
                                value: _weeklySessions ?? 'Non spécifié',
                                showArrow: true,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => SettingsOptionPage(
                                        headerTitle: 'Mes informations',
                                        headerSubtitle: 'Séances par semaine',
                                        options: const [
                                          SettingsOptionItem(value: '1', label: '1'),
                                          SettingsOptionItem(value: '2', label: '2'),
                                          SettingsOptionItem(value: '3', label: '3'),
                                          SettingsOptionItem(value: '4', label: '4'),
                                          SettingsOptionItem(value: '5', label: '5'),
                                          SettingsOptionItem(value: '6+', label: '6+'),
                                        ],
                                        initialValue: _weeklySessions ?? '',
                                        onChanged: (val) {
                                          setState(() => _weeklySessions = val);
                                          _updateProfileField('weekly_sessions', val);
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // 10. Compléments alimentaires
                              _InfoTile(
                                title: 'Compléments alimentaires',
                                value: _supplements ?? 'Non spécifié',
                                showArrow: true,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => SettingsOptionPage(
                                        headerTitle: 'Mes informations',
                                        headerSubtitle: 'Compléments alimentaires',
                                        options: const [
                                          SettingsOptionItem(value: 'Oui', label: 'Oui'),
                                          SettingsOptionItem(value: 'Non', label: 'Non'),
                                        ],
                                        initialValue: _supplements ?? '',
                                        onChanged: (val) {
                                          setState(() => _supplements = val);
                                          _updateProfileField('supplements', val);
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
  final bool showArrow;
  final bool isMuted;
  final VoidCallback? onTap;

  const _InfoTile({
    required this.title,
    required this.value,
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
  final ValueChanged<String>? onSubmitted;

  const _EditableTextTile({
    required this.title,
    required this.controller,
    required this.focusNode,
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
                        hintText: 'Non spécifié',
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
                        text.isEmpty ? 'Non spécifié' : text,
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
