import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/app_strings.dart';
import '../../domain/models/task_model.dart';
import '../viewmodels/task_cubit.dart';
import '../viewmodels/calendar_cubit.dart';
import 'atmosphere_background.dart';

void showTaskFormModal(
    BuildContext context,
    TaskCubit taskCubit, {
      TaskModel? task,
      bool isShared = false,
      String? forcedCalendarId,
      DateTime? forcedDate,
    }) {
  final calendarCubit = context.read<CalendarCubit>();
  Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (ctx) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: taskCubit),
          BlocProvider.value(value: calendarCubit),
        ],
        child: _TaskFormScreen(
          task: task,
          isSharedContext: isShared,
          forcedCalendarId: forcedCalendarId,
          forcedDate: forcedDate,
        ),
      ),
    ),
  );
}

void showTaskDetailsModal(
    BuildContext context,
    TaskCubit taskCubit,
    TaskModel task,
    ) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: taskCubit),
        BlocProvider.value(value: context.read<CalendarCubit>()),
      ],
      child: _TaskDetailsModal(task: task),
    ),
  );
}

class _TaskDetailsModal extends StatelessWidget {
  final TaskModel task;
  const _TaskDetailsModal({required this.task});

  @override
  Widget build(BuildContext context) {
    final start = DateTime.tryParse(task.dataInizio)?.toLocal() ?? DateTime.now();
    final end = DateTime.tryParse(task.dataFine)?.toLocal() ?? DateTime.now();
    final safeBottom = MediaQuery.of(context).padding.bottom;

    final orario = task.tuttoIlGiorno
        ? AppStrings.dettagliDicituraTuttoGiorno
        : "${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}";

    final bgColor = task.sharedCalendarId != null
        ? AppAtmospheres.sharedBg
        : AppAtmospheres.privateBg;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.fromLTRB(30, 30, 30, safeBottom + 20),
            decoration: BoxDecoration(
              color: bgColor.withValues(alpha: 0.9),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.titolo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.white70, size: 18),
                    const SizedBox(width: 8),
                    Text(orario, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 20),
                if (task.descrizione.isNotEmpty) ...[
                  const Text(AppStrings.dettagliDescrizioneLabel, style: TextStyle(color: Colors.white54, fontSize: 14)),
                  const SizedBox(height: 5),
                  Text(task.descrizione, style: const TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 30),
                ],
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white24,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        icon: const Icon(Icons.edit, color: Colors.white),
                        label: const Text('Modifica', style: TextStyle(color: Colors.white)),
                        onPressed: () {
                          Navigator.pop(context);
                          showTaskFormModal(
                            context,
                            context.read<TaskCubit>(),
                            task: task,
                            isShared: task.sharedCalendarId != null,
                            forcedCalendarId: task.sharedCalendarId,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        icon: const Icon(Icons.delete, color: Colors.white),
                        label: const Text(AppStrings.btnElimina, style: TextStyle(color: Colors.white)),
                        onPressed: () {
                          context.read<TaskCubit>().deleteTask(task.id);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskFormScreen extends StatefulWidget {
  final TaskModel? task;
  final bool isSharedContext;
  final String? forcedCalendarId;
  final DateTime? forcedDate;

  const _TaskFormScreen({
    this.task,
    this.isSharedContext = false,
    this.forcedCalendarId,
    this.forcedDate,
  });

  @override
  State<_TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<_TaskFormScreen> {
  final _titoloCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final List<String> _hours = List.generate(24, (index) => index.toString().padLeft(2, '0'));
  final List<String> _minutes = ['00', '15', '30', '45'];

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  List<dynamic> _savedTemplates = [];

  final List<String> _colorsPalette = [
    '#06B6D4', '#10B981', '#E11D48', '#F59E0B', '#6366F1', '#F97316',
  ];

  String _selectedColor = '#06B6D4';
  DateTime _selectedDate = DateTime.now();
  String _startHour = '09';
  String _startMinute = '00';
  String _endHour = '10';
  String _endMinute = '00';
  bool _isAllDay = false;
  String _priorita = 'LOW';
  String? _selectedSharedCalendarId;

  late Color bgColor;

  String get _storageKey {
    if (widget.isSharedContext && _selectedSharedCalendarId != null) {
      return 'task_templates_shared_${_selectedSharedCalendarId}';
    }
    return 'task_templates_private';
  }

  @override
  void initState() {
    super.initState();
    bgColor = widget.isSharedContext ? AppAtmospheres.sharedBg : AppAtmospheres.privateBg;
    _selectedSharedCalendarId = widget.forcedCalendarId;
    if (widget.forcedDate != null) _selectedDate = widget.forcedDate!;

    if (widget.task != null) {
      final t = widget.task!;
      _titoloCtrl.text = t.titolo;
      _descCtrl.text = t.descrizione;
      _isAllDay = t.tuttoIlGiorno;
      _priorita = t.priorita;
      _selectedColor = t.colore;
      _selectedSharedCalendarId = t.sharedCalendarId;

      final start = DateTime.tryParse(t.dataInizio)?.toLocal() ?? DateTime.now();
      final end = DateTime.tryParse(t.dataFine)?.toLocal() ?? DateTime.now().add(const Duration(hours: 1));

      _selectedDate = start;
      _startHour = start.hour.toString().padLeft(2, '0');
      _startMinute = _snapMinute(start.minute);
      _endHour = end.hour.toString().padLeft(2, '0');
      _endMinute = _snapMinute(end.minute);
    }
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    String? templatesJson = await _storage.read(key: _storageKey);
    if (templatesJson != null) {
      try {
        setState(() => _savedTemplates = jsonDecode(templatesJson));
      } catch (_) {}
    } else {
      setState(() => _savedTemplates = []);
    }
  }

  Future<void> _saveCurrentAsTemplate() async {
    final titoloInserito = _titoloCtrl.text.trim();
    if (titoloInserito.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Il titolo non può essere vuoto.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    bool giaEsiste = _savedTemplates.any((t) => (t['titolo'] ?? '').toString().toLowerCase() == titoloInserito.toLowerCase());
    if (giaEsiste) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esiste già un modello con questo nome!'), backgroundColor: Colors.orangeAccent),
      );
      return;
    }

    final newTemplate = {
      'titolo': titoloInserito,
      'descrizione': _descCtrl.text.trim(),
      'colore': _selectedColor,
      'tuttoIlGiorno': _isAllDay,
      'startHour': _startHour,
      'startMinute': _startMinute,
      'endHour': _endHour,
      'endMinute': _endMinute,
    };

    setState(() => _savedTemplates.add(newTemplate));
    await _storage.write(key: _storageKey, value: jsonEncode(_savedTemplates));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Modello salvato con successo!'), backgroundColor: Colors.green),
      );
    }
  }

  void _applyTemplate(Map<String, dynamic> t) {
    setState(() {
      _titoloCtrl.text = t['titolo'] ?? '';
      _descCtrl.text = t['descrizione'] ?? '';
      _selectedColor = t['colore'] ?? '#06B6D4';
      _isAllDay = t['tuttoIlGiorno'] ?? false;
      _startHour = t['startHour'] ?? '09';
      _startMinute = t['startMinute'] ?? '00';
      _endHour = t['endHour'] ?? '10';
      _endMinute = t['endMinute'] ?? '00';
    });
  }

  String _snapMinute(int min) {
    if (min < 15) return '00';
    if (min < 30) return '15';
    if (min < 45) return '30';
    return '45';
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(primary: Colors.white, onPrimary: Colors.black, surface: bgColor, onSurface: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _submit() {
    if (_titoloCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Il titolo è obbligatorio.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    DateTime start = _isAllDay ? DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day) : DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, int.parse(_startHour), int.parse(_startMinute));
    DateTime end = _isAllDay ? DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59) : DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, int.parse(_endHour), int.parse(_endMinute));

    if (widget.task == null) {
      context.read<TaskCubit>().createTask(
        titolo: _titoloCtrl.text.trim(),
        descrizione: _descCtrl.text.trim(),
        dataInizio: start,
        dataFine: end,
        priorita: _priorita,
        tuttoIlGiorno: _isAllDay,
        sharedCalendarId: _selectedSharedCalendarId,
        colore: _selectedColor,
      );
    } else {
      context.read<TaskCubit>().updateTask(
        widget.task!.id,
        titolo: _titoloCtrl.text.trim(),
        descrizione: _descCtrl.text.trim(),
        dataInizio: start,
        dataFine: end,
        priorita: _priorita,
        tuttoIlGiorno: _isAllDay,
        sharedCalendarId: _selectedSharedCalendarId,
        colore: _selectedColor,
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.task == null ? (widget.isSharedContext ? AppStrings.taskCondivisoTitle : AppStrings.taskPrivatoTitle) : AppStrings.taskModificaTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: 'Salva come modello',
            onPressed: _saveCurrentAsTemplate,
          ),
        ],
      ),
      body: Stack(
        children: [
          AtmosphereBackground(backgroundColor: bgColor, circleColors: widget.isSharedContext ? AppAtmospheres.sharedCircles : AppAtmospheres.privateCircles),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 20, 20, safeBottom + 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(AppStrings.formGiorno, style: TextStyle(color: Colors.white70, fontSize: 16)),
                          Text("${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _titoloCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "${AppStrings.formTitoloHint} *",
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text("Scegli Colore Task:", style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _colorsPalette.map((hexStr) {
                      final cleaned = hexStr.replaceAll('#', '');
                      final colorObj = Color(int.parse('FF$cleaned', radix: 16));
                      final isSelected = _selectedColor == hexStr;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = hexStr),
                        child: Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            color: colorObj,
                            shape: BoxShape.circle,
                            border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 3),
                          ),
                          child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                        ),
                      );
                    }).toList(),
                  ),
                  // BARRA ORIZZONTALE RAPIDA DEI TEMPLATE (PILLOLE LEGGIBILI)
                  if (_savedTemplates.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text("Modelli Rapidi:", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 42,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _savedTemplates.length,
                        itemBuilder: (context, i) {
                          final t = _savedTemplates[i] as Map<String, dynamic>;
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: Material(
                              color: Colors.black.withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: Colors.white70, width: 1),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _applyTemplate(t),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  child: Center(
                                    child: Text(
                                      t['titolo'] ?? 'Modello',
                                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  CheckboxListTile(
                    title: const Text(AppStrings.formTuttoIlGiorno, style: TextStyle(color: Colors.white)),
                    value: _isAllDay,
                    onChanged: (v) => setState(() => _isAllDay = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    activeColor: Colors.white,
                    checkColor: bgColor,
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _descCtrl,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: AppStrings.formDescrizioneHint,
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      onPressed: _submit,
                      child: const Text(AppStrings.btnSalva, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}