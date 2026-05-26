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
    final start =
        DateTime.tryParse(task.dataInizio)?.toLocal() ?? DateTime.now();
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
                    const Icon(
                      Icons.access_time,
                      color: Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      orario,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (task.descrizione.isNotEmpty) ...[
                  const Text(
                    AppStrings.dettagliDescrizioneLabel,
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    task.descrizione,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 30),
                ],
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white24,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        icon: const Icon(Icons.edit, color: Colors.white),
                        label: const Text(
                          'Modifica',
                          style: TextStyle(color: Colors.white),
                        ),
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
                          backgroundColor: Colors.redAccent.withValues(
                            alpha: 0.8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        icon: const Icon(Icons.delete, color: Colors.white),
                        label: const Text(
                          AppStrings.btnElimina,
                          style: TextStyle(color: Colors.white),
                        ),
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
  final List<String> _hours = List.generate(
    24,
    (index) => index.toString().padLeft(2, '0'),
  );
  final List<String> _minutes = ['00', '15', '30', '45'];

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  List<dynamic> _savedTemplates = [];

  final List<String> _colorsPalette = [
    '#06B6D4',
    '#10B981',
    '#E11D48',
    '#F59E0B',
    '#6366F1',
    '#F97316',
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

  @override
  void initState() {
    super.initState();
    _loadTemplates();

    bgColor = widget.isSharedContext
        ? AppAtmospheres.sharedBg
        : AppAtmospheres.privateBg;
    _selectedSharedCalendarId = widget.forcedCalendarId;
    if (widget.forcedDate != null) {
      _selectedDate = widget.forcedDate!;
    }

    if (widget.task != null) {
      final t = widget.task!;
      _titoloCtrl.text = t.titolo;
      _descCtrl.text = t.descrizione;
      _isAllDay = t.tuttoIlGiorno;
      _priorita = t.priorita;
      _selectedColor = t.colore;
      _selectedSharedCalendarId = t.sharedCalendarId;

      final start =
          DateTime.tryParse(t.dataInizio)?.toLocal() ?? DateTime.now();
      final end =
          DateTime.tryParse(t.dataFine)?.toLocal() ??
          DateTime.now().add(const Duration(hours: 1));

      _selectedDate = start;
      _startHour = start.hour.toString().padLeft(2, '0');
      _startMinute = _snapMinute(start.minute);
      _endHour = end.hour.toString().padLeft(2, '0');
      _endMinute = _snapMinute(end.minute);
    }
  }

  Future<void> _loadTemplates() async {
    String? templatesJson = await _storage.read(key: 'task_templates');
    if (templatesJson != null) {
      setState(() {
        _savedTemplates = jsonDecode(templatesJson);
      });
    }
  }

  Future<void> _saveCurrentAsTemplate() async {
    if (_titoloCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'I campi obbligatori contrassegnati da * non possono essere vuoti.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final newTemplate = {
      'titolo': _titoloCtrl.text.trim(),
      'descrizione': _descCtrl.text.trim(),
      'colore': _selectedColor,
      'tuttoIlGiorno': _isAllDay,
      'startHour': _startHour,
      'startMinute': _startMinute,
      'endHour': _endHour,
      'endMinute': _endMinute,
    };

    setState(() {
      _savedTemplates.add(newTemplate);
    });

    await _storage.write(
      key: 'task_templates',
      value: jsonEncode(_savedTemplates),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Modello salvato con successo!'),
          backgroundColor: Colors.green,
        ),
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

  void _showTemplatesModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: 40,
        ),
        decoration: BoxDecoration(
          color: bgColor.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
            const Text(
              "Modelli Salvati",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Seleziona un modello rapido per compilare automaticamente il task.",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 20),
            _savedTemplates.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Center(
                      child: Text(
                        "Nessun modello salvato.",
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  )
                : Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _savedTemplates.length,
                      itemBuilder: (context, i) {
                        final t = _savedTemplates[i] as Map<String, dynamic>;

                        Color taskColor = Colors.cyanAccent;
                        try {
                          final cleaned = (t['colore'] ?? '#06B6D4').replaceAll(
                            '#',
                            '',
                          );
                          taskColor = Color(int.parse('FF$cleaned', radix: 16));
                        } catch (_) {}

                        return Card(
                          color: Colors.white.withValues(alpha: 0.1),
                          elevation: 0,
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 15,
                              height: 15,
                              decoration: BoxDecoration(
                                color: taskColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            title: Text(
                              t['titolo'] ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              t['tuttoIlGiorno'] == true
                                  ? "Tutto il giorno"
                                  : "${t['startHour']}:${t['startMinute']} - ${t['endHour']}:${t['endMinute']}",
                              style: const TextStyle(color: Colors.white70),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              onPressed: () {
                                setState(() {
                                  _savedTemplates.removeAt(i);
                                });
                                _storage.write(
                                  key: 'task_templates',
                                  value: jsonEncode(_savedTemplates),
                                );
                                Navigator.pop(ctx);
                                _showTemplatesModal();
                              },
                            ),
                            onTap: () {
                              _applyTemplate(t);
                              Navigator.pop(ctx);
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
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
          colorScheme: ColorScheme.dark(
            primary: Colors.white,
            onPrimary: Colors.black,
            surface: bgColor,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  bool _isValidTime(String h1, String m1, String h2, String m2) {
    final startMins = int.parse(h1) * 60 + int.parse(m1);
    final endMins = int.parse(h2) * 60 + int.parse(m2);
    return startMins < endMins;
  }

  void _onStartTimeChanged(String h, String m) {
    if (!_isValidTime(h, m, _endHour, _endMinute)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Attenzione: l\'orario di inizio non può superare la fine. L\'orario di fine è stato aggiornato automaticamente.',
          ),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      int newEndHour = (int.parse(h) + 1) % 24;
      setState(() {
        _startHour = h;
        _startMinute = m;
        _endHour = newEndHour.toString().padLeft(2, '0');
      });
    } else {
      setState(() {
        _startHour = h;
        _startMinute = m;
      });
    }
  }

  void _onEndTimeChanged(String h, String m) {
    if (!_isValidTime(_startHour, _startMinute, h, m)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Errore: l\'orario di fine non può essere antecedente o uguale all\'inizio.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } else {
      setState(() {
        _endHour = h;
        _endMinute = m;
      });
    }
  }

  void _submit() {
    if (_titoloCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'I campi obbligatori contrassegnati da * non possono essere vuoti.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    DateTime start;
    DateTime end;

    if (_isAllDay) {
      start = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        0,
        0,
      );
      end = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        23,
        59,
      );
    } else {
      start = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        int.parse(_startHour),
        int.parse(_startMinute),
      );
      end = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        int.parse(_endHour),
        int.parse(_endMinute),
      );

      if (!start.isBefore(end)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Errore: la data di fine deve essere successiva a quella di inizio.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

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

  Widget _buildTimeDropdown(
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: bgColor,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
          style: const TextStyle(color: Colors.white, fontSize: 16),
          items: items
              .map(
                (String item) =>
                    DropdownMenuItem<String>(value: item, child: Text(item)),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    String screenTitle = widget.task == null
        ? (widget.isSharedContext
              ? AppStrings.taskCondivisoTitle
              : AppStrings.taskPrivatoTitle)
        : AppStrings.taskModificaTitle;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          screenTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: 'Salva come modello',
            onPressed: _saveCurrentAsTemplate,
          ),
          IconButton(
            icon: const Icon(Icons.library_books),
            tooltip: 'Carica modello',
            onPressed: _showTemplatesModal,
          ),
        ],
      ),
      body: Stack(
        children: [
          AtmosphereBackground(
            backgroundColor: bgColor,
            circleColors: widget.isSharedContext
                ? AppAtmospheres.sharedCircles
                : AppAtmospheres.privateCircles,
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 20, 20, safeBottom + 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            AppStrings.formGiorno,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  const Text(
                    "Scegli Colore Task:",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _colorsPalette.map((hexStr) {
                      final cleaned = hexStr.replaceAll('#', '');
                      final colorObj = Color(
                        int.parse('FF$cleaned', radix: 16),
                      );
                      final isSelected = _selectedColor == hexStr;

                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = hexStr),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: colorObj,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: colorObj.withValues(alpha: 0.6),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : [],
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  Theme(
                    data: ThemeData(unselectedWidgetColor: Colors.white54),
                    child: CheckboxListTile(
                      title: const Text(
                        AppStrings.formTuttoIlGiorno,
                        style: TextStyle(color: Colors.white),
                      ),
                      value: _isAllDay,
                      onChanged: (v) => setState(() => _isAllDay = v ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      activeColor: Colors.white,
                      checkColor: bgColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (!_isAllDay) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          AppStrings.formInizio,
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        Row(
                          children: [
                            _buildTimeDropdown(
                              _startHour,
                              _hours,
                              (v) => _onStartTimeChanged(v!, _startMinute),
                            ),
                            const Text(
                              " : ",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            _buildTimeDropdown(
                              _startMinute,
                              _minutes,
                              (v) => _onStartTimeChanged(_startHour, v!),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          AppStrings.formFine,
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        Row(
                          children: [
                            _buildTimeDropdown(
                              _endHour,
                              _hours,
                              (v) => _onEndTimeChanged(v!, _endMinute),
                            ),
                            const Text(
                              " : ",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            _buildTimeDropdown(
                              _endMinute,
                              _minutes,
                              (v) => _onEndTimeChanged(_endHour, v!),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 15),
                  TextField(
                    controller: _descCtrl,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: AppStrings.formDescrizioneHint,
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: _submit,
                      child: const Text(
                        AppStrings.btnSalva,
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
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
  }
}
