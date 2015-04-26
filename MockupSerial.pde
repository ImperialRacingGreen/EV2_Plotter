int mockupValue = 0;
int mockupDirection = 10;
int time = 0;
String mockupSerialFunction() {
  mockupValue = (mockupValue + mockupDirection);
  if (mockupValue > 100)
    mockupDirection = -10;
  else if (mockupValue < -100)
    mockupDirection = 10;
  String r = "@";
  for (int i = 0; i<23; i++) {
    switch (i) {
    // RPM
    case 0:
      r += (int)(100*cos(time*(2*3.14)/5000)+1000) +",";
      break;
    // TORQUE
    case 1:
      r += (100*cos(time*(2*3.14)/5000)+100)/2+",";
      break;
    // MOTOR TEMP
    case 2:
      r += 10*cos(time*(2*3.14)/5000)+50+",";
      break;
    // MC TEMP
    case 3:
      r += 10*cos(time*(2*3.14)/5000)+80+",";
      break;
    // MC VOLTAGE
    case 4:
      r += 50*cos(time*(2*3.14)/5000)+300+",";
      break;
    // MC CURRENT
    case 5:
      r += 10*cos(time*(2*3.14)/5000)+100+",";
      break;
    // RFE
    case 6:
      r += (int)(2*cos(time*(2*3.14)/5000)+2)/2+",";
      break;
    // FRG
    case 7:
      r += (int)(2*cos(time*(2*3.14)/5000)+2)/2+",";
      break;
    // PACK VOLTAGE
    case 8:
      r += mockupValue/32+",";
      break;
    // BATTERY TEMP
    case 9:
      r += mockupValue/32+",";
      break;
    // BATTERY MIN TEMP
    case 10:
      r += mockupValue/32+",";
      break;
    // BATTERY MAX TEMP
    case 11:
      r += mockupValue/8+",";
      break;
    // BMS STATUS
    case 12:
      r += mockupValue/16+",";
      break;
    // BATTERY FAULT
    case 13:
      r += mockupValue/32+",";
      break;
    // ISOLATION FAULT
    case 14:
      r += mockupValue/32+",";
      break;
    // AVERAGE THROTTLE
    case 15:
      r += mockupValue/32+",";
      break;
    // LV BATTERY
    case 16:
      r += mockupValue/32+",";
      break;
    // HV
    case 17:
      r += mockupValue/32+",";
      break;
    // TSA
    case 18:
      r += mockupValue/32+",";
      break;
    // RELAY
    case 19:
      r += mockupValue/32+",";
      break;
    // CAR STATE
    case 20:
      r += mockupValue/32+",";
      break;
    // CAR STATE
    case 21:
      r += mockupValue/32+",";
      break;
    // CAR STATE
    case 22:
      r += mockupValue/32+"\n";
      break;
    }
    time++;
  }
  delay(100);
  return r;
}
