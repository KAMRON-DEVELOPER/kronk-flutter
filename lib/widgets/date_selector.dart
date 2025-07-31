import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kronk/constants/my_theme.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/screens/user/edit_profile_screen.dart';
import 'package:kronk/utility/extensions.dart';

class DatePicker extends ConsumerStatefulWidget {
  final DateTime? initialValue;
  final Function(DateTime?) onDatePicked;

  const DatePicker({super.key, this.initialValue, required this.onDatePicked});

  @override
  ConsumerState<DatePicker> createState() => _DatePickerState();
}

class _DatePickerState extends ConsumerState<DatePicker> {
  late DateTime selectedDate;
  late final FixedExtentScrollController dayController;
  late final FixedExtentScrollController monthController;
  late final FixedExtentScrollController yearController;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialValue ?? DateTime.now();
    dayController = FixedExtentScrollController(initialItem: selectedDate.day - 1);
    monthController = FixedExtentScrollController(initialItem: selectedDate.month - 1);
    yearController = FixedExtentScrollController(initialItem: 99);
  }

  @override
  void dispose() {
    dayController.dispose();
    monthController.dispose();
    yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeNotifierProvider);

    return Column(
      children: [
        const FieldLabel(label: 'birthdate'),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.dp),
          decoration: BoxDecoration(color: theme.secondaryBackground, borderRadius: BorderRadius.circular(12.dp)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${selectedDate.toLocal()}'.split(' ')[0]),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Day selector
                  _buildDaySelector(theme),
                  // Month selector
                  _buildMonthSelector(theme),
                  // Year selector
                  _buildYearSelector(theme),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDaySelector(MyTheme theme) {
    return Container(
      width: 60,
      height: 150,
      alignment: Alignment.center,
      child: ListWheelScrollView.useDelegate(
        controller: dayController,
        itemExtent: 50,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (index) {
          setState(() {
            selectedDate = DateTime(selectedDate.year, selectedDate.month, index + 1);
          });
          widget.onDatePicked(selectedDate);
        },
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: 31,
          builder: (context, index) {
            return Center(
              child: Text(
                '${index + 1}',
                style: GoogleFonts.quicksand(fontSize: selectedDate.day - 1 == index ? 24 : 16, color: selectedDate.day - 1 == index ? theme.primaryText : theme.secondaryText),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMonthSelector(MyTheme theme) {
    return Container(
      width: 60,
      height: 150,
      alignment: Alignment.center,
      child: ListWheelScrollView.useDelegate(
        controller: monthController,
        itemExtent: 50,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (index) {
          setState(() {
            selectedDate = DateTime(selectedDate.year, index + 1, selectedDate.day);
          });
          widget.onDatePicked(selectedDate);
        },
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: 12,
          builder: (context, index) {
            return Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(fontSize: selectedDate.month - 1 == index ? 24 : 16, color: selectedDate.month - 1 == index ? theme.primaryText : theme.secondaryText),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildYearSelector(MyTheme theme) {
    return Container(
      width: 80,
      height: 150,
      alignment: Alignment.center,
      child: ListWheelScrollView.useDelegate(
        controller: yearController,
        itemExtent: 50,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (index) {
          setState(() {
            selectedDate = DateTime(DateTime.now().year - 99 + index, selectedDate.month, selectedDate.day);
          });
          widget.onDatePicked(selectedDate);
        },
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: 100,
          builder: (context, index) {
            return Center(
              child: Text(
                '${DateTime.now().year - 99 + index}',
                style: TextStyle(
                  fontSize: selectedDate.year == DateTime.now().year - 99 + index ? 24 : 16,
                  color: selectedDate.year == DateTime.now().year - 99 + index ? theme.primaryText : theme.secondaryText,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
