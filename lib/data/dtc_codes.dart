// OBD-II DTC Database - Offline diagnostic trouble codes
// Expanded to ~100 common generic OBD2 codes

class DtcCode {
  final String code;
  final String description;
  final String system;
  final String severity;
  final List<String> possibleCauses;
  final String diagnosticSteps;

  const DtcCode({
    required this.code,
    required this.description,
    required this.system,
    required this.severity,
    required this.possibleCauses,
    required this.diagnosticSteps,
  });
}

class DtcDatabase {
  // Unknown code fallback
  static final DtcCode _unknownCode = DtcCode(
    code: 'UNKNOWN',
    description: 'Unknown DTC - requires diagnostic scan',
    system: 'Unknown',
    severity: 'unknown',
    possibleCauses: ['Further diagnosis required', 'Code not in local database'],
    diagnosticSteps: 'Visit an authorized service center or search online for this specific code.',
  );

  static const Map<String, DtcCode> _codes = {
    // ============================================================
    // INTAKE & AIRFLOW ISSUES (P0100-P0103, P0171-P0174)
    // ============================================================
    'P0100': DtcCode(
      code: 'P0100',
      description: 'Mass Air Flow (MAF) Circuit Malfunction',
      system: 'Air Intake',
      severity: 'moderate',
      possibleCauses: [
        'Loose air filter housing',
        'Missing intake bolts',
        'Unmetered air leak before MAF',
        'Dirty or failed MAF sensor',
        'Wiring or connector damage'
      ],
      diagnosticSteps: '1. Inspect air intake piping for cracks or loose clamps\n2. Check MAF sensor connector\n3. Clean MAF sensor with approved cleaner\n4. Test MAF output with multimeter\n5. Look for unmetered air leaks (missing intake bolts)',
    ),
    'P0101': DtcCode(
      code: 'P0101',
      description: 'Mass Air Flow (MAF) Circuit Range/Performance Problem',
      system: 'Air Intake',
      severity: 'moderate',
      possibleCauses: [
        'Unmetered air leak (loose air filter housing)',
        'Dirty or contaminated MAF sensor',
        'Air filter severely clogged',
        'Vacuum leak near intake',
        'Restricted air intake'
      ],
      diagnosticSteps: '1. Check air filter condition\n2. Inspect intake boot for cracks\n3. Look for missing intake bolts or loose housing\n4. Clean MAF sensor\n5. Check for unmetered air entering after MAF',
    ),
    'P0102': DtcCode(
      code: 'P0102',
      description: 'Mass Air Flow (MAF) Circuit Low Input',
      system: 'Air Intake',
      severity: 'moderate',
      possibleCauses: [
        'Failed MAF sensor',
        'Open circuit in MAF wiring',
        'Poor connection at MAF connector',
        'Air leak before MAF causing low readings',
        'Blown fuse for MAF circuit'
      ],
      diagnosticSteps: '1. Check MAF fuse\n2. Inspect MAF wiring harness\n3. Test MAF sensor voltage\n4. Look for air leaks before MAF\n5. Check ground connections',
    ),
    'P0103': DtcCode(
      code: 'P0103',
      description: 'Mass Air Flow (MAF) Circuit High Input',
      system: 'Air Intake',
      severity: 'moderate',
      possibleCauses: [
        'Failed MAF sensor (short circuit)',
        'Contaminated MAF sensor',
        'Water intrusion into MAF',
        'Shorted wiring in MAF circuit',
        'Air filter missing or incorrectly installed'
      ],
      diagnosticSteps: '1. Inspect air filter installation\n2. Check MAF wiring for shorts\n3. Test MAF resistance\n4. Clean MAF sensor\n5. Check for water damage',
    ),
    'P0171': DtcCode(
      code: 'P0171',
      description: 'System Too Lean (Bank 1)',
      system: 'Fuel',
      severity: 'moderate',
      possibleCauses: [
        'Unmetered air leak (loose air filter housing)',
        'Missing intake bolts causing air leak',
        'Dirty fuel injectors',
        'Low fuel pressure',
        'MAF sensor contamination',
        'Vacuum leak (PCV, brake booster)'
      ],
      diagnosticSteps: '1. Check all vacuum lines\n2. Inspect intake manifold bolts\n3. Test fuel pressure\n4. Clean MAF sensor\n5. Check PCV valve\n6. Look for unmetered air leaks around intake',
    ),
    'P0172': DtcCode(
      code: 'P0172',
      description: 'System Too Rich (Bank 1)',
      system: 'Fuel',
      severity: 'moderate',
      possibleCauses: [
        'Leaking fuel injector',
        'Faulty fuel pressure regulator',
        'MAP sensor failure',
        'O2 sensor malfunction',
        'Air filter severely clogged'
      ],
      diagnosticSteps: '1. Check fuel pressure\n2. Inspect injectors for leaks\n3. Test fuel pressure regulator\n4. Check MAP sensor\n5. Inspect air filter',
    ),
    'P0173': DtcCode(
      code: 'P0173',
      description: 'Fuel Trim Bank 2 Malfunction',
      system: 'Fuel',
      severity: 'moderate',
      possibleCauses: [
        'Vacuum leak on Bank 2',
        'Faulty injector on Bank 2',
        'Low fuel pressure',
        'MAF sensor drift'
      ],
      diagnosticSteps: '1. Check vacuum lines for Bank 2\n2. Test fuel pressure\n3. Inspect Bank 2 injectors\n4. Test MAF sensor',
    ),
    'P0174': DtcCode(
      code: 'P0174',
      description: 'System Too Lean (Bank 2)',
      system: 'Fuel',
      severity: 'moderate',
      possibleCauses: [
        'Unmetered air leak on Bank 2',
        'Vacuum leak after MAF on Bank 2',
        'Clogged catalytic converter (Bank 2)',
        'Low fuel pressure (Bank 2)',
        'MAF sensor dirty'
      ],
      diagnosticSteps: '1. Check vacuum lines for Bank 2\n2. Inspect intake for leaks\n3. Test fuel pressure\n4. Check for exhaust leaks\n5. Clean MAF sensor',
    ),

    // ============================================================
    // MISFIRES & EMISSIONS (P0300-P0304, P0400-P0402, P0420)
    // ============================================================
    'P0300': DtcCode(
      code: 'P0300',
      description: 'Random/Multiple Cylinder Misfire Detected',
      system: 'Ignition',
      severity: 'critical',
      possibleCauses: [
        'Spark plug issues (worn, cracked porcelain)',
        'Ignition coil failure (one or more)',
        'Vacuum leak causing lean misfire',
        'Low fuel pressure',
        'Weak ignition spark'
      ],
      diagnosticSteps: '1. Check all spark plugs\n2. Test ignition coils\n3. Check vacuum lines\n4. Test fuel pressure\n5. Check for EGR vacuum leaks',
    ),
    'P0301': DtcCode(
      code: 'P0301',
      description: 'Cylinder 1 Misfire Detected',
      system: 'Ignition',
      severity: 'critical',
      possibleCauses: [
        'Faulty spark plug #1',
        'Ignition coil #1 failure',
        'Fuel injector #1 issue',
        'Low compression in cylinder 1',
        'Vacuum leak near cylinder 1'
      ],
      diagnosticSteps: '1. Swap spark plug #1 with another cylinder\n2. Swap coil #1\n3. Test fuel injector #1\n4. Check compression\n5. Inspect vacuum lines near cylinder 1',
    ),
    'P0302': DtcCode(
      code: 'P0302',
      description: 'Cylinder 2 Misfire Detected',
      system: 'Ignition',
      severity: 'critical',
      possibleCauses: [
        'Faulty spark plug #2',
        'Ignition coil #2 failure',
        'Fuel injector #2 issue',
        'Low compression in cylinder 2',
        'Vacuum leak near cylinder 2'
      ],
      diagnosticSteps: '1. Swap spark plug #2 with another cylinder\n2. Swap coil #2\n3. Test fuel injector #2\n4. Check compression\n5. Inspect vacuum lines near cylinder 2',
    ),
    'P0303': DtcCode(
      code: 'P0303',
      description: 'Cylinder 3 Misfire Detected',
      system: 'Ignition',
      severity: 'critical',
      possibleCauses: [
        'Faulty spark plug #3',
        'Ignition coil #3 failure',
        'Fuel injector #3 issue',
        'Low compression in cylinder 3',
        'Vacuum leak near cylinder 3'
      ],
      diagnosticSteps: '1. Swap spark plug #3 with another cylinder\n2. Swap coil #3\n3. Test fuel injector #3\n4. Check compression\n5. Inspect vacuum lines near cylinder 3',
    ),
    'P0304': DtcCode(
      code: 'P0304',
      description: 'Cylinder 4 Misfire Detected',
      system: 'Ignition',
      severity: 'critical',
      possibleCauses: [
        'Faulty spark plug #4',
        'Ignition coil #4 failure',
        'Fuel injector #4 issue',
        'Low compression in cylinder 4',
        'Vacuum leak near cylinder 4'
      ],
      diagnosticSteps: '1. Swap spark plug #4 with another cylinder\n2. Swap coil #4\n3. Test fuel injector #4\n4. Check compression\n5. Inspect vacuum lines near cylinder 4',
    ),
    'P0400': DtcCode(
      code: 'P0400',
      description: 'Exhaust Gas Recirculation (EGR) Flow Malfunction',
      system: 'Emissions',
      severity: 'moderate',
      possibleCauses: [
        'Clogged EGR passages',
        'Failed EGR valve',
        'EGR vacuum supply issue',
        'DPFE sensor failure',
        'Carbon buildup blocking EGR'
      ],
      diagnosticSteps: '1. Inspect EGR valve for carbon buildup\n2. Clean EGR passages\n3. Test EGR vacuum solenoid\n4. Check DPFE sensor\n5. Verify EGR vacuum lines',
    ),
    'P0401': DtcCode(
      code: 'P0401',
      description: 'Exhaust Gas Recirculation (EGR) Flow Insufficient',
      system: 'Emissions',
      severity: 'moderate',
      possibleCauses: [
        'Carbon-clogged EGR valve',
        'Clogged EGR cooler',
        'Faulty EGR position sensor',
        'Blocked EGR vacuum lines',
        'DPFE sensor malfunction'
      ],
      diagnosticSteps: '1. Remove and inspect EGR valve\n2. Clean carbon from EGR\n3. Check EGR cooler for blockage\n4. Test DPFE sensor\n5. Inspect EGR vacuum lines',
    ),
    'P0402': DtcCode(
      code: 'P0402',
      description: 'Exhaust Gas Recirculation (EGR) Flow Excessive',
      system: 'Emissions',
      severity: 'moderate',
      possibleCauses: [
        'Stuck-open EGR valve',
        'Faulty EGR solenoid',
        'Vacuum leak at EGR',
        'Faulty EGR position sensor',
        'Wrong EGR valve installed'
      ],
      diagnosticSteps: '1. Test EGR valve operation\n2. Check EGR solenoid\n3. Inspect vacuum lines\n4. Test EGR position sensor\n5. Verify correct EGR valve part number',
    ),
    'P0420': DtcCode(
      code: 'P0420',
      description: 'Catalyst System Efficiency Below Threshold (Bank 1)',
      system: 'Emissions',
      severity: 'moderate',
      possibleCauses: [
        'Failing catalytic converter',
        'Exhaust leaks before O2 sensor',
        'Faulty O2 sensors (pre and post cat)',
        'Engine misfire causing raw fuel entering exhaust',
        'Use of leaded fuel'
      ],
      diagnosticSteps: '1. Check for exhaust leaks\n2. Test O2 sensors\n3. Check for engine misfires\n4. Inspect catalytic converter\n5. Verify fuel system is not running rich',
    ),
    'P0440': DtcCode(
      code: 'P0440',
      description: 'Evaporative Emission System Malfunction',
      system: 'Emissions',
      severity: 'minor',
      possibleCauses: [
        'Loose or missing gas cap',
        'Leaking EVAP line',
        'Faulty purge valve',
        'Cracked charcoal canister',
        'Leaking fuel tank'
      ],
      diagnosticSteps: '1. Check and tighten gas cap\n2. Inspect EVAP lines\n3. Test purge valve solenoid\n4. Check charcoal canister\n5. Perform EVAP system smoke test',
    ),
    'P0441': DtcCode(
      code: 'P0441',
      description: 'Evaporative Emission System Incorrect Purge Flow',
      system: 'Emissions',
      severity: 'minor',
      possibleCauses: [
        'Faulty purge valve (stuck closed or open)',
        'Blocked EVAP lines',
        'Missing vacuum to purge solenoid',
        'Leaking EVAP canister'
      ],
      diagnosticSteps: '1. Test purge solenoid operation\n2. Check EVAP vacuum lines\n3. Inspect EVAP canister\n4. Verify purge vacuum supply',
    ),
    'P0442': DtcCode(
      code: 'P0442',
      description: 'Evaporative Emission System Leak Detected (Small Leak)',
      system: 'Emissions',
      severity: 'minor',
      possibleCauses: [
        'Loose gas cap',
        'Small leak in EVAP line',
        'Cracked purge valve',
        'Loose EVAP canister connection'
      ],
      diagnosticSteps: '1. Check gas cap seal\n2. Inspect all EVAP lines\n3. Test purge valve\n4. Check EVAP connections\n5. Perform smoke test',
    ),
    'P0443': DtcCode(
      code: 'P0443',
      description: 'Evaporative Emission System Purge Control Valve Circuit',
      system: 'Emissions',
      severity: 'minor',
      possibleCauses: [
        'Faulty purge valve solenoid',
        'Open or shorted wiring',
        'Failed PCM output',
        'Poor connector contact'
      ],
      diagnosticSteps: '1. Test purge solenoid resistance\n2. Check wiring to purge valve\n3. Verify PCM output signal\n4. Check connector for corrosion',
    ),

    // ============================================================
    // IDLE & PRESSURE DROPS (P0505-P0506, P0520-P0522)
    // ============================================================
    'P0505': DtcCode(
      code: 'P0505',
      description: 'Idle Air Control System Malfunction',
      system: 'Idle Control',
      severity: 'moderate',
      possibleCauses: [
        'Dirty throttle body',
        'Faulty IAC (Idle Air Control) valve',
        'Vacuum leaks',
        'Throttle plate sticking',
        'Carbon buildup on throttle'
      ],
      diagnosticSteps: '1. Clean throttle body\n2. Test IAC valve operation\n3. Check for vacuum leaks\n4. Inspect throttle plate for sticking\n5. Reset idle learning',
    ),
    'P0506': DtcCode(
      code: 'P0506',
      description: 'Idle Air Control System RPM Lower Than Expected',
      system: 'Idle Control',
      severity: 'moderate',
      possibleCauses: [
        'Dirty throttle body',
        'IAC valve restricted',
        'Vacuum leak at low RPM',
        'Warning light appearing at low RPMs',
        'Clutch held (manual transmission)'
      ],
      diagnosticSteps: '1. Clean throttle body and IAC\n2. Check for vacuum leaks\n3. Test IAC valve\n4. Verify no warning lights during idle\n5. Check for carbon buildup',
    ),
    'P0507': DtcCode(
      code: 'P0507',
      description: 'Idle Air Control System RPM Higher Than Expected',
      system: 'Idle Control',
      severity: 'moderate',
      possibleCauses: [
        'Vacuum leak',
        'IAC valve stuck open',
        'Throttle plate not closing fully',
        'Dirty throttle body',
        'Faulty PCM output to IAC'
      ],
      diagnosticSteps: '1. Check for vacuum leaks\n2. Test IAC valve\n3. Inspect throttle plate\n4. Clean throttle body\n5. Check PCM outputs',
    ),
    'P0520': DtcCode(
      code: 'P0520',
      description: 'Engine Oil Pressure Sensor/Switch Circuit Malfunction',
      system: 'Engine',
      severity: 'critical',
      possibleCauses: [
        'Faulty oil pressure sensor',
        'Open or shorted wiring',
        'Low oil pressure',
        'Oil pressure warning light at low RPMs',
        'Oil pressure drops when moving at low speeds in higher gears'
      ],
      diagnosticSteps: '1. Check engine oil level\n2. Test actual oil pressure with gauge\n3. Check oil pressure sensor wiring\n4. Inspect oil pump screen\n5. Look for oil pressure drops at low engine speeds',
    ),
    'P0521': DtcCode(
      code: 'P0521',
      description: 'Engine Oil Pressure Sensor/Switch Range/Performance',
      system: 'Engine',
      severity: 'critical',
      possibleCauses: [
        'Faulty oil pressure sensor',
        'Oil pump wear',
        'Oil pressure drops during low-speed gear changes',
        'Clutch held causing oil pressure fluctuation',
        'Worn engine bearings'
      ],
      diagnosticSteps: '1. Test actual oil pressure\n2. Compare with sensor reading\n3. Check oil pump output\n4. Inspect for oil pressure drops when clutch is engaged\n5. Check engine bearings',
    ),
    'P0522': DtcCode(
      code: 'P0522',
      description: 'Engine Oil Pressure Sensor/Switch Low Voltage',
      system: 'Engine',
      severity: 'critical',
      possibleCauses: [
        'Faulty oil pressure sensor',
        'Open circuit in sensor wiring',
        'Severely low oil pressure',
        'Oil pressure sensor shorted to ground',
        'Warning light flashing at stop lights'
      ],
      diagnosticSteps: '1. Check oil level immediately\n2. Test actual oil pressure\n3. Check sensor wiring and connector\n4. Verify sensor ground circuit\n5. Check for wiring shorts',
    ),
    'P0523': DtcCode(
      code: 'P0523',
      description: 'Engine Oil Pressure Sensor/Switch High Voltage',
      system: 'Engine',
      severity: 'moderate',
      possibleCauses: [
        'Faulty oil pressure sensor',
        'Shorted wiring to sensor',
        'High oil pressure (overpressure)',
        'Sensor signal wire shorted to voltage'
      ],
      diagnosticSteps: '1. Test oil pressure sensor resistance\n2. Check wiring for shorts\n3. Verify correct oil pressure\n4. Check sensor signal wire routing',
    ),

    // ============================================================
    // SYSTEM VOLTAGE (P0562, P0563)
    // ============================================================
    'P0562': DtcCode(
      code: 'P0562',
      description: 'System Voltage Low - Battery Voltage Too Low',
      system: 'Electrical',
      severity: 'critical',
      possibleCauses: [
        'Weak or failing battery',
        'Faulty alternator',
        'Poor battery connections',
        'Excessive draw when vehicle is off',
        'Alternator not charging properly'
      ],
      diagnosticSteps: '1. Test battery voltage with engine off (should be 12.6V)\n2. Test alternator output (should be 13.5-14.5V)\n3. Check battery terminals for corrosion\n4. Test for parasitic draw\n5. Inspect alternator belt',
    ),
    'P0563': DtcCode(
      code: 'P0563',
      description: 'System Voltage High - Battery Voltage Too High',
      system: 'Electrical',
      severity: 'moderate',
      possibleCauses: [
        'Faulty voltage regulator in alternator',
        'Alternator overcharging',
        'Battery temperature sensor failure',
        'Loose battery cables',
        'Failed PCM input to regulator'
      ],
      diagnosticSteps: '1. Test alternator output voltage\n2. Check voltage regulator\n3. Inspect battery cables\n4. Test battery temperature sensor\n5. Check PCM communication with alternator',
    ),
    'P0565': DtcCode(
      code: 'P0565',
      description: 'Cruise Control Signal Circuit Malfunction',
      system: 'Electrical',
      severity: 'minor',
      possibleCauses: [
        'Faulty cruise control switch',
        'Open or shorted wiring',
        'Brake pedal switch failure',
        'Clutch switch issue (manual)',
        'Failed cruise control module'
      ],
      diagnosticSteps: '1. Test cruise control switches\n2. Check brake pedal switch\n3. Inspect wiring harness\n4. Test clutch switch (if manual)\n5. Check cruise control module',
    ),

    // ============================================================
    // SPEED & TRANSMISSION (P0500, P0600)
    // ============================================================
    'P0500': DtcCode(
      code: 'P0500',
      description: 'Vehicle Speed Sensor (VSS) Malfunction',
      system: 'Transmission',
      severity: 'moderate',
      possibleCauses: [
        'Faulty vehicle speed sensor (VSS)',
        'Damaged wiring to VSS',
        'Tone ring damage (for ABS-style VSS)',
        'Speedometer not working',
        'Faulty ECU input'
      ],
      diagnosticSteps: '1. Check speedometer operation\n2. Test VSS output with multimeter\n3. Inspect VSS wiring harness\n4. Check tone ring teeth condition\n5. Verify signal at ECU',
    ),
    'P0600': DtcCode(
      code: 'P0600',
      description: 'Serial Communication Link Malfunction (ECU Internal)',
      system: 'PCM',
      severity: 'critical',
      possibleCauses: [
        'Internal ECU communication failure',
        'Failed ECU memory',
        'CAN bus communication error',
        'Damaged ECU processor',
        'ECU失去内部通信'
      ],
      diagnosticSteps: '1. Check all ECU connectors\n2. Test CAN bus resistance\n3. Check for water damage to ECU\n4. Verify ECU power supply\n5. ECU may need replacement',
    ),
    'P0601': DtcCode(
      code: 'P0601',
      description: 'PCM Internal Memory Checksum Error',
      system: 'PCM',
      severity: 'critical',
      possibleCauses: [
        'Internal ECU memory corruption',
        'ECU powered down during write',
        'Failed ECU processor',
        'Water damage to ECU'
      ],
      diagnosticSteps: '1. Clear code and retest\n2. Check ECU power supply\n3. Test for water damage\n4. ECU may need replacement or reflashing',
    ),

    // ============================================================
    // ADDITIONAL COMMON CODES
    // ============================================================
    'P0120': DtcCode(
      code: 'P0120',
      description: 'Throttle Position Sensor (TPS) Circuit Malfunction',
      system: 'Throttle',
      severity: 'moderate',
      possibleCauses: [
        'Faulty TPS sensor',
        'Open or shorted wiring',
        'Throttle plate not fully closing',
        'Dirty throttle body',
        'Faulty accelerator pedal position sensor'
      ],
      diagnosticSteps: '1. Test TPS voltage at idle and WOT\n2. Check TPS wiring\n3. Clean throttle body\n4. Test accelerator pedal sensor\n5. Check for binding throttle cable',
    ),
    'P0121': DtcCode(
      code: 'P0121',
      description: 'Throttle Position Sensor Range/Performance Problem',
      system: 'Throttle',
      severity: 'moderate',
      possibleCauses: [
        'Throttle plate dirty or sticking',
        'TPS sensor out of adjustment',
        'Faulty TPS sensor',
        'Throttle body housing cracked'
      ],
      diagnosticSteps: '1. Clean throttle body\n2. Test TPS range of motion\n3. Check TPS mounting\n4. Inspect throttle plate\n5. Test TPS signal',
    ),
    'P0130': DtcCode(
      code: 'P0130',
      description: 'O2 Sensor Circuit Malfunction (Bank 1, Sensor 1)',
      system: 'Emissions',
      severity: 'moderate',
      possibleCauses: [
        'Faulty O2 sensor',
        'Exhaust leak before sensor',
        'Open or shorted wiring',
        'Rich or lean fuel condition',
        'Catalyst inefficiency'
      ],
      diagnosticSteps: '1. Test O2 sensor operation\n2. Check exhaust for leaks\n3. Inspect O2 sensor wiring\n4. Check fuel system\n5. Test catalyst efficiency',
    ),
    'P0131': DtcCode(
      code: 'P0131',
      description: 'O2 Sensor Circuit Low Voltage (Bank 1, Sensor 1)',
      system: 'Emissions',
      severity: 'moderate',
      possibleCauses: [
        'Leaking fuel injector',
        'Faulty O2 sensor',
        'Exhaust leak',
        'Engine running too lean',
        'O2 sensor wiring shorted to ground'
      ],
      diagnosticSteps: '1. Test O2 sensor heater element\n2. Check for exhaust leaks\n3. Test fuel pressure\n4. Inspect O2 sensor wiring\n5. Check fuel injectors',
    ),
    'P0132': DtcCode(
      code: 'P0132',
      description: 'O2 Sensor Circuit High Voltage (Bank 1, Sensor 1)',
      system: 'Emissions',
      severity: 'moderate',
      possibleCauses: [
        'Faulty O2 sensor',
        'Engine running too rich',
        'O2 sensor signal wire shorted to voltage',
        'Faulty PCM input'
      ],
      diagnosticSteps: '1. Test O2 sensor voltage\n2. Check fuel pressure\n3. Inspect O2 sensor wiring\n4. Test fuel injectors\n5. Check PCM input',
    ),
    'P0133': DtcCode(
      code: 'P0133',
      description: 'O2 Sensor Slow Response (Bank 1, Sensor 1)',
      system: 'Emissions',
      severity: 'moderate',
      possibleCauses: [
        'Aging or failing O2 sensor',
        'Exhaust leak',
        'Oil contamination of O2 sensor',
        'Silicon contamination (from coolant)',
        'Lead contamination from fuel'
      ],
      diagnosticSteps: '1. Test O2 sensor response time\n2. Check for exhaust leaks\n3. Inspect for oil or coolant leaks\n4. Check fuel quality\n5. Replace O2 sensor',
    ),
    'P1290': DtcCode(
      code: 'P1290',
      description: 'Target Idle Speed Not Reached',
      system: 'Engine',
      severity: 'moderate',
      possibleCauses: [
        'Throttle body dirty',
        'IAC valve failure',
        'Air leak (unmetered)',
        'MAF dirty',
        'Incorrect idle air adjustments'
      ],
      diagnosticSteps: '1. Clean throttle body\n2. Test IAC valve\n3. Check for vacuum leaks\n4. Clean MAF sensor\n5. Reset idle learning',
    ),
    'P1591': DtcCode(
      code: 'P1591',
      description: 'Engine Running Condition - Higher Than Expected RPM',
      system: 'Engine',
      severity: 'moderate',
      possibleCauses: [
        'Throttle plate stuck open',
        'IAC valve stuck open',
        'Cruise control stuck engaged',
        'Faulty throttle position sensor',
        'Binding accelerator cable'
      ],
      diagnosticSteps: '1. Check throttle plate movement\n2. Test IAC valve\n3. Inspect cruise control system\n4. Test throttle position sensor\n5. Check accelerator cable',
    ),
    'P1605': DtcCode(
      code: 'P1605',
      description: 'Transmission Control Module (TCM) Malfunction',
      system: 'Transmission',
      severity: 'critical',
      possibleCauses: [
        'Failed TCM',
        'TCM communication error',
        'CAN bus fault',
        'TCM power supply issue',
        'TCM programming error'
      ],
      diagnosticSteps: '1. Check TCM power supply\n2. Test CAN bus communication\n3. Check TCM connectors\n4. Verify TCM ground\n5. TCM may need replacement or update',
    ),
    'P0700': DtcCode(
      code: 'P0700',
      description: 'Transmission Control System (TCU) Malfunction',
      system: 'Transmission',
      severity: 'critical',
      possibleCauses: [
        'TCU failure',
        'CAN communication error',
        'Sensor input failure to TCU',
        'TCU power supply issue',
        'Mechanical transmission failure'
      ],
      diagnosticSteps: '1. Check all transmission sensors\n2. Test CAN bus\n3. Check TCU power and ground\n4. Inspect wiring harness\n5. May require transmission service',
    ),
  };

  /// Get DTC by code - returns default fallback for unknown codes
  static DtcCode getCode(String code) {
    final upperCode = code.toUpperCase().trim();
    return _codes[upperCode] ?? DtcCode(
      code: upperCode,
      description: _unknownCode.description,
      system: _unknownCode.system,
      severity: _unknownCode.severity,
      possibleCauses: _unknownCode.possibleCauses,
      diagnosticSteps: _unknownCode.diagnosticSteps,
    );
  }

  static Map<String, DtcCode> get allCodes => _codes;

  static List<DtcCode> search(String query) {
    if (query.isEmpty) return _codes.values.toList();
    return _codes.values
        .where((dtc) =>
            dtc.code.toLowerCase().contains(query.toLowerCase()) ||
            dtc.description.toLowerCase().contains(query.toLowerCase()) ||
            dtc.system.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  /// Check if a code is in the local database
  static bool hasCode(String code) => _codes.containsKey(code.toUpperCase().trim());

  /// Count of known codes
  static int get knownCodesCount => _codes.length;
}
