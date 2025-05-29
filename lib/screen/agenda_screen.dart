import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/tarea.dart';
import '../services/firestore_service.dart';
import 'create_task_screen.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  List<Tarea> _tareas = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Agenda")),
      body: _userId == null
          ? const Center(child: Text("Usuario no autenticado"))
          : StreamBuilder<List<Tarea>>(
        stream: _firestoreService.getTareas(_userId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          _tareas = snapshot.data ?? [];
          final citas = _mapTareasToAppointments(_tareas);

          return SingleChildScrollView(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("Tus tareas", style: TextStyle(fontSize: 20)),
                ),
                SizedBox(
                  height: 600, // o MediaQuery.of(context).size.height
                  child: SfCalendar(
                    view: CalendarView.month,
                    appointmentTimeTextFormat: 'HH:mm',
                    dataSource: TaskDataSource(citas),
                    todayHighlightColor: Theme.of(context).primaryColor,
                    timeSlotViewSettings: TimeSlotViewSettings(
                      timeFormat: 'HH:mm',
                    ),
                    monthViewSettings: const MonthViewSettings(
                      showAgenda: true,
                      appointmentDisplayMode:
                      MonthAppointmentDisplayMode.appointment,
                    ),
                    onTap: (calendarTapDetails) {
                      if (calendarTapDetails.targetElement ==
                          CalendarElement.appointment) {
                        final Appointment? apt =
                            calendarTapDetails.appointments?.first;
                        if (apt != null) {
                          final tarea = _tareas.firstWhere(
                                (t) =>
                            t.titulo == apt.subject &&
                                t.fechaEntrega == apt.startTime,
                          );
                          if (tarea != null) {
                            _abrirDetalleTarea(tarea);
                          }
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),

    );
  }

  List<Appointment> _mapTareasToAppointments(List<Tarea> tareas) {
    return tareas
        .where((t) => t.fechaEntrega != null)
        .map((t) => Appointment(
      startTime: t.fechaEntrega!,
      endTime: t.fechaEntrega!.add(const Duration(hours: 1)),
      subject: t.titulo,
      notes: t.descripcion,
      color: t.completada ? Colors.grey : Colors.teal,
    ))
        .toList();
  }

  void _abrirDetalleTarea(Tarea tarea) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateTaskScreen(tarea: tarea)),
    );
    setState(() {});
  }
}

class TaskDataSource extends CalendarDataSource {
  TaskDataSource(List<Appointment> source) {
    appointments = source;
  }
}
