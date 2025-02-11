import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../utils/operations/bills_operations.dart';
import '../utils/operations/payment_history_operations.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  double _totalAmount = 0.0;
  String _selectedPeriod = 'Semana';
  String _selectedChartType = 'Vendas';
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  List<BarChartGroupData> _barChartData = [];
  String _errorMessage = '';

  // NEW: State for dynamic y-axis viewport
  double _currentMinY = 0.0;
  double _currentMaxY = 500.0;

  @override
  void initState() {
    super.initState();
    _fetchChartData();
  }

  void _fetchChartData() async {
    if (_selectedChartType == 'Vendas') {
      await _fetchBillsChartData();
    } else if (_selectedChartType == 'Pagamentos') {
      await _fetchPaymentsChartData();
    }
  }

  Future<void> _fetchPaymentsChartData() async {
    Map<String, double> data;
    if (_selectedPeriod == 'Semana') {
      data = await getTotalAmountForWeekPayments();
    } else if (_selectedPeriod == 'Mês') {
      data = await getTotalAmountForMonthPayments(_selectedMonth);
      data = _groupDataByMonthRanges(data);
    } else {
      data = await getTotalAmountForYearPayments(_selectedYear);
    }

    setState(() {
      _barChartData = _generateBarChartData(data);
      _totalAmount = data.values.fold(0.0, (sum, item) => sum + item);
      double computedMax = _getDynamicMaxY();
      if (_selectedPeriod == 'Ano') {
        _currentMaxY = computedMax < 7000 ? 7000 : computedMax;
        _currentMinY = 100;
      } else if (_selectedPeriod == 'Mês') {
        _currentMaxY = computedMax < 1000 ? 1000 : computedMax;
        _currentMinY = 100;
      } else {
        _currentMaxY = computedMax < 500 ? 500 : computedMax;
        _currentMinY = 0;
      }
    });
  }

  Future<void> _fetchBillsChartData() async {
    Map<String, double> data;
    if (_selectedPeriod == 'Semana') {
      data = await getTotalAmountForWeekBills();
    } else if (_selectedPeriod == 'Mês') {
      data = await getTotalAmountForMonthBills(_selectedMonth);
      data = _groupDataByMonthRanges(data);
    } else {
      data = await getTotalAmountForYearBills(_selectedYear);
    }

    setState(() {
      _barChartData = _generateBarChartData(data);
      _totalAmount = data.values.fold(0.0, (sum, item) => sum + item);
      double computedMax = _getDynamicMaxY();
      if (_selectedPeriod == 'Ano') {
        _currentMaxY = computedMax < 7000 ? 7000 : computedMax;
        _currentMinY = 100;
      } else if (_selectedPeriod == 'Mês') {
        _currentMaxY = computedMax < 1000 ? 1000 : computedMax;
        _currentMinY = 100;
      } else {
        _currentMaxY = computedMax < 500 ? 500 : computedMax;
        _currentMinY = 0;
      }
    });
  }

  Map<String, double> _groupDataByMonthRanges(Map<String, double> data) {
    Map<String, double> groupedData = {
      '1-6': 0.0,
      '7-12': 0.0,
      '13-18': 0.0,
      '19-24': 0.0,
      '25-31': 0.0,
    };

    DateFormat dateFormat = DateFormat('dd/MM/yyyy');

    data.forEach((key, value) {
      try {
        DateTime date = dateFormat.parse(key);
        int day = date.day;
        if (day >= 1 && day <= 6) {
          groupedData['1-6'] = groupedData['1-6']! + value;
        } else if (day >= 7 && day <= 12) {
          groupedData['7-12'] = groupedData['7-12']! + value;
        } else if (day >= 13 && day <= 18) {
          groupedData['13-18'] = groupedData['13-18']! + value;
        } else if (day >= 19 && day <= 24) {
          groupedData['19-24'] = groupedData['19-24']! + value;
        } else if (day >= 25) {
          groupedData['25-31'] = groupedData['25-31']! + value;
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Erro ao agrupar os dados por intervalos de mês.';
        });
      }
    });

    return groupedData;
  }

  List<BarChartGroupData> _generateBarChartData(Map<String, double> data) {
    List<BarChartGroupData> barGroups = [];
    int index = 0;
    data.forEach((key, value) {
      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: value,
              color: Colors.yellow,
              width: 15,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(3),
                topRight: Radius.circular(3),
              ),
            ),
          ],
        ),
      );
      index++;
    });
    return barGroups;
  }

  // NEW: Calculate dynamic max from _barChartData
  double _getDynamicMaxY() {
    double dataMax = 0.0;
    for (var group in _barChartData) {
      for (var rod in group.barRods) {
        if (rod.toY > dataMax) dataMax = rod.toY;
      }
    }
    return dataMax;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(110),
          child: Container(
            padding: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.grey[700],
            ),
            child: Column(
              children: [
                Text(
                  'Relatórios',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 26),
                ),
                SizedBox(height: 5),
                _periodButtons(),
              ],
            ),
          ),
        ),
        backgroundColor: Colors.grey[800],
        body: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_selectedPeriod == 'Mês') _monthDropdown(),
              if (_selectedPeriod == 'Ano') _yearDropdown(),
              const SizedBox(height: 10),
              _chartType(),
              const SizedBox(height: 10),
              _buildChart(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _periodButtons() {
    double width = 120;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        button(
          'Semana',
          width,
          Colors.black,
          _selectedPeriod == 'Semana' ? Colors.yellow[700] : Colors.yellow,
          () {
            setState(() {
              _selectedPeriod = 'Semana';
              _fetchChartData();
            });
          },
        ),
        button(
          'Mês',
          width,
          Colors.black,
          _selectedPeriod == 'Mês' ? Colors.yellow[700] : Colors.yellow,
          () {
            setState(() {
              _selectedPeriod = 'Mês';
              _fetchChartData();
            });
          },
        ),
        button(
          'Ano',
          width,
          Colors.black,
          _selectedPeriod == 'Ano' ? Colors.yellow[700] : Colors.yellow,
          () {
            setState(() {
              _selectedPeriod = 'Ano';
              _fetchChartData();
            });
          },
        ),
      ],
    );
  }

  Widget _monthDropdown() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          'Selecionar Período:',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        SizedBox(width: 10),
        DropdownButton<int>(
          value: _selectedMonth,
          dropdownColor: Colors.grey[700],
          items: List.generate(12, (index) {
            return DropdownMenuItem(
              value: index + 1,
              child: Text(
                DateFormat('MMMM', 'pt_BR').format(DateTime(0, index + 1)),
                style: TextStyle(color: Colors.white),
              ),
            );
          }),
          onChanged: (value) {
            setState(() {
              _selectedMonth = value!;
              _fetchChartData();
            });
          },
        ),
      ],
    );
  }

  Widget _yearDropdown() {
    int currentYear = DateTime.now().year;
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          'Selecionar Período:',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        SizedBox(width: 10),
        DropdownButton<int>(
          value: _selectedYear,
          dropdownColor: Colors.grey[700],
          items: List.generate(5, (index) {
            int year = currentYear - index;
            return DropdownMenuItem(
              value: year,
              child: Text(
                year.toString(),
                style: TextStyle(color: Colors.white),
              ),
            );
          }),
          onChanged: (value) {
            setState(() {
              _selectedYear = value!;
              _fetchChartData();
            });
          },
        ),
      ],
    );
  }

  Widget _buildChart() {
    return Column(
      children: [
        Container(
          height: 450,
          padding: EdgeInsets.all(12.0),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Período: ${_selectedPeriod == 'Ano' ? _selectedYear : DateFormat('MMMM', 'pt_BR').format(DateTime(0, _selectedMonth))}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 20),
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              // NEW: Wrap chart with GestureDetector for infinite vertical scroll (limited downward)
              Flexible(
                child: GestureDetector(
                  onVerticalDragUpdate: (details) {
                    // UPDATED: Set factor to 2.0 for month, 4.0 for year, and 1.0 otherwise
                    double factor = _selectedPeriod == 'Ano'
                        ? 4.0
                        : _selectedPeriod == 'Mês'
                            ? 2.0
                            : 1.0;
                    double shift = details.delta.dy * factor;
                    double baseMin = _selectedPeriod == 'Semana' ? 0 : 100;
                    double range = _currentMaxY - _currentMinY;
                    double newMin = _currentMinY + shift;
                    double newMax = _currentMaxY + shift;
                    if (newMin < baseMin) {
                      newMin = baseMin;
                      newMax = baseMin + range;
                    }
                    setState(() {
                      _currentMinY = newMin;
                      _currentMaxY = newMax;
                    });
                  },
                  child: BarChart(
                    BarChartData(
                      maxY: _currentMaxY,
                      minY: _currentMinY,
                      gridData: FlGridData(
                        show: true,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.white.withOpacity(0.1),
                            strokeWidth: 1,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: Colors.white.withOpacity(0.1),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: _selectedPeriod == 'Ano'
                                ? 70
                                : _selectedPeriod == 'Mês'
                                    ? 70
                                    : 70,
                            getTitlesWidget: (value, meta) {
                              // NEW: Only show round numbers (multiples of 100)
                              if (value.round() % 100 != 0) return Container();
                              return Text('R\$ ${value.round()}',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12));
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return _getBottomTitles(value);
                            },
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border(
                          left: BorderSide(
                              color: Colors.white.withOpacity(0.2), width: 1),
                          bottom: BorderSide(
                              color: Colors.white.withOpacity(0.2), width: 1),
                          top: BorderSide.none,
                          right: BorderSide.none,
                        ),
                      ),
                      barGroups: _barChartData,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10),
        Container(
          height: 60,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Center(
            child: Text('Total: R\$ $_totalAmount',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
        )
      ],
    );
  }

  Widget _getBottomTitles(double value) {
    if (_selectedPeriod == 'Semana') {
      const daysOfWeek = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
      if (value.toInt() >= 0 && value.toInt() < daysOfWeek.length) {
        return Text(daysOfWeek[value.toInt()],
            style: TextStyle(color: Colors.white));
      }
    } else if (_selectedPeriod == 'Mês') {
      const monthRanges = ['1-6', '7-12', '13-18', '19-24', '25-31'];
      if (value.toInt() >= 0 && value.toInt() < monthRanges.length) {
        return Text(monthRanges[value.toInt()],
            style: TextStyle(color: Colors.white));
      }
    } else if (_selectedPeriod == 'Ano') {
      const monthsOfYear = [
        'Jan',
        'Fev',
        'Mar',
        'Abr',
        'Mai',
        'Jun',
        'Jul',
        'Ago',
        'Set',
        'Out',
        'Nov',
        'Dez'
      ];
      if (value.toInt() >= 0 && value.toInt() < monthsOfYear.length) {
        return Transform.rotate(
          angle: -0.75, // Rotate the text by -0.5 radians (~28.65 degrees)
          child: Text(monthsOfYear[value.toInt()],
              style: TextStyle(color: Colors.white)),
        );
      }
    }
    return Text('');
  }

  Widget _chartType() {
    double width = 180;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        button(
          'Vendas',
          width,
          Colors.white,
          _selectedChartType == 'Vendas' ? Colors.grey[600] : Colors.grey[700],
          () {
            setState(() {
              _selectedChartType = 'Vendas';
              _fetchChartData();
            });
          },
        ),
        button(
          'Pagamentos',
          width,
          Colors.white,
          _selectedChartType == 'Pagamentos'
              ? Colors.grey[600]
              : Colors.grey[700],
          () {
            setState(() {
              _selectedChartType = 'Pagamentos';
              _fetchChartData();
            });
          },
        ),
      ],
    );
  }

  ElevatedButton button(String textLabel, double width, Color textColor,
      Color? backgroundColor, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        fixedSize: Size.fromWidth(width),
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      child: Text(
        textLabel,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
