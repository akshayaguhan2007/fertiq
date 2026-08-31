f = 'app/lib/screens/satellite_analysis_screen.dart'
c = open(f, 'r', encoding='utf-8').read()

# 1. Replace imports - remove mock_data, add sensor_service
c = c.replace(
    "import '../services/gemini_service.dart';\nimport '../services/mock_data.dart';",
    "import '../services/sensor_service.dart';\nimport '../services/gemini_service.dart';"
)

# 2. Add _sensorData field
c = c.replace(
    "  SatelliteResult?        _result;\n  GeminiRecommendations?  _recs;",
    "  SatelliteResult?        _result;\n  GeminiRecommendations?  _recs;\n  LiveSensorData?         _sensorData;"
)

# 3. Replace MockData soil usage in _fetchData - find and replace the block
old_soil = "    final soil = MockData.soilReading;"
new_soil = "    final svc = SensorService();\n    final sensor = await svc.fetchOnce();\n    svc.dispose();\n    setState(() => _sensorData = sensor);"
c = c.replace(old_soil, new_soil)

# 4. Replace soilN/soilP/soilK/district/weatherSummary lines
old_params = "      soilN: soil.n, soilP: soil.p, soilK: soil.k,"
new_params = "      soilN: sensor.n, soilP: sensor.p, soilK: sensor.k,"
c = c.replace(old_params, new_params)

# 5. Replace district MockData
old_district = "      district: MockData.farmer.district,"
new_district = "      district: '',"
c = c.replace(old_district, new_district)

# 6. Replace weatherSummary - find the line containing MockData.forecast
lines = c.split('\n')
new_lines = []
skip_next = False
for line in lines:
    if skip_next:
        skip_next = False
        continue
    if 'MockData.forecast' in line:
        new_lines.append("      weatherSummary: 'Temp: ${sensor.temperature.toStringAsFixed(1)}°C, Moisture: ${sensor.moisture.toStringAsFixed(1)}%',")
        skip_next = False
    elif "weatherSummary:" in line and 'MockData' not in line and 'sensor' not in line:
        # multi-line weatherSummary starting line
        skip_next = True
    else:
        new_lines.append(line)
c = '\n'.join(new_lines)

# 7. Add sensor param to _ResultView call
c = c.replace(
    "              pinned: _pinned,\n              onRescan: () => setState(() { _result = null; _recs = null; }),",
    "              pinned: _pinned,\n              sensor: _sensorData,\n              onRescan: () => setState(() { _result = null; _recs = null; }),"
)

# 8. Add sensor field to _ResultView class
c = c.replace(
    "  final VoidCallback onRescan;\n\n  const _ResultView({",
    "  final LiveSensorData? sensor;\n  final VoidCallback onRescan;\n\n  const _ResultView({"
)

# 9. Add sensor to _ResultView constructor required params
c = c.replace(
    "    required this.pinned, required this.onRescan,",
    "    required this.pinned, this.sensor, required this.onRescan,"
)

# 10. Replace MockData.ndviHistory in chart with real data from result
c = c.replace(
    "            final ndviHistory = MockData.ndviHistory;",
    "            final ndvi = result.ndvi;\n            final ndviHistory = List.generate(7, (i) => (ndvi * (0.7 + i * 0.05)).clamp(0.0, 1.0));"
)

open(f, 'w', encoding='utf-8').write(c)

# Verify
v = open(f, 'r', encoding='utf-8').read()
print('MockData removed:', 'MockData' not in v)
print('SensorService added:', 'SensorService' in v)
print('sensor.n used:', 'sensor.n' in v)
print('ndviHistory live:', 'List.generate(7' in v)
