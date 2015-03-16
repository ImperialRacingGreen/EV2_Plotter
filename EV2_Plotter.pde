// import libraries
import java.awt.Frame;
import java.awt.BorderLayout;
import controlP5.*; // http://www.sojamo.de/libraries/controlP5/
import processing.serial.*;

/* SETTINGS BEGIN */

// If you want to debug the plotter without using a real serial port set this to true
boolean mockupSerial = true;

/* SETTINGS END */

Serial serialPort; // Serial port object

// interface stuff
ControlP5 cp5;

// Settings for the plotter are saved in this file
JSONObject plotterConfigJSON;

// helper for saving the executing path
String topSketchPath = "";

int window_width = 1500;
int window_height = 750;
int font_size = 17;
String font_type = "Verdana";

// Labels for Variables
Textlabel rpmLabel;
Textlabel torqueLabel;
Textlabel motorTempLabel;
Textlabel mcTempLabel;
Textlabel mcVoltageLabel;
Textlabel mcCurrentLabel;
Textlabel rfeLabel;
Textlabel frgLabel;

Textlabel bmsVoltageLabel;
Textlabel bmsTempLabel;
Textlabel bmsMinTemp;
Textlabel bmsMaxTemp;
Textlabel bmsStatus;

Textlabel batteryFaultLabel;
Textlabel isolationFaultLabel;
Textlabel aveThrottleLabel;
Textlabel lvBatteryLabel;
Textlabel hvLabel;
Textlabel tsaLabel;
Textlabel relayLabel;
Textlabel carStateLabel;

// For Logging
PrintWriter output;
int seconds = 0;
int millis = 0;
int now = 0;
ArrayList<String> values = new ArrayList<String>();

int i;

// For Plotting
Graph LineGraph = new Graph(235, 150, 750, 450, color (20, 20, 200));
float[][] lineGraphValues = new float[3][100];
float[] lineGraphSampleNumbers = new float[100];
color[] graphColors = new color[3];

void setup() {
  frame.setTitle("EV2 DYNO");

  size(window_width, window_height);
  graphColors[0] = color(38, 166, 91);
  graphColors[1] = color(248, 148, 6);
  graphColors[2] = color(207, 0, 15);

  // settings save file
  topSketchPath = sketchPath;
  plotterConfigJSON = loadJSONObject(topSketchPath+"/plotter_config.json");

  // gui
  cp5 = new ControlP5(this);
  int x = 180;
  int y = 135;

  cp5.addTextfield("lgMaxY").setPosition(x, y).setText(getPlotterConfigString("lgMaxY")).setWidth(40).setAutoClear(false);
  cp5.addTextfield("lgMinY").setPosition(x, y = y + 450).setText(getPlotterConfigString("lgMinY")).setWidth(40).setAutoClear(false);
  
  setChartSettings();
  // build x axis values for the line graph
  for (int i=0; i<lineGraphValues.length; i++) {
    for (int k=0; k<lineGraphValues[0].length; k++) {
      lineGraphValues[i][k] = 0;
      if (i==0)
        lineGraphSampleNumbers[k] = k;
    }
  }

  x = 1050;
  y = 10;
  cp5.addTextlabel("multipliers").setText("multipliers").setPosition(x=x, y=y).setColor(0);
  cp5.addTextfield("lgMultiplier1").setPosition(x=x, y=y+15).setText(getPlotterConfigString("lgMultiplier1")).setColorCaptionLabel(0).setWidth(40).setAutoClear(false);
  cp5.addTextfield("lgMultiplier2").setPosition(x=x, y=y+30).setText(getPlotterConfigString("lgMultiplier2")).setColorCaptionLabel(0).setWidth(40).setAutoClear(false);
  cp5.addTextfield("lgMultiplier3").setPosition(x, y=y+45).setText(getPlotterConfigString("lgMultiplier3")).setColorCaptionLabel(0).setWidth(40).setAutoClear(false);
  
  x = 1120;
  y = 10;
  cp5.addTextlabel("label").setText("on/off").setPosition(x=x, y=y).setColor(0);
  cp5.addToggle("lgVisible1").setPosition(x=x, y=y+15).setValue(int(getPlotterConfigString("lgVisible1"))).setMode(ControlP5.SWITCH).setColorActive(graphColors[0]);
  cp5.addToggle("lgVisible2").setPosition(x=x, y=y+30).setValue(int(getPlotterConfigString("lgVisible2"))).setMode(ControlP5.SWITCH).setColorActive(graphColors[0]);
  cp5.addToggle("lgVisible3").setPosition(x=x, y=y+45).setValue(int(getPlotterConfigString("lgVisible3"))).setMode(ControlP5.SWITCH).setColorActive(graphColors[0]);

  rpmLabel = cp5.addTextlabel("rpmLabel")
                .setColor(0)
                .setFont(createFont(font_type,font_size))
                ;

  torqueLabel = cp5.addTextlabel("torqueLabel")
                   .setColor(0)
                   .setFont(createFont(font_type,font_size))
                   ;
            
  motorTempLabel  = cp5.addTextlabel("motorTempLabel")
                       .setColor(0)
                       .setFont(createFont(font_type,font_size))
                       ;

  mcTempLabel = cp5.addTextlabel("mcTempLabel")
                   .setColor(0)
                   .setFont(createFont(font_type,font_size))
                   ;

  mcVoltageLabel = cp5.addTextlabel("mcVoltageLabel")
                      .setColor(0)
                      .setFont(createFont(font_type,font_size))
                      ;

  mcCurrentLabel = cp5.addTextlabel("mcCurrentLabel")
                      .setColor(0)
                      .setFont(createFont(font_type,font_size))
                      ;

  rfeLabel = cp5.addTextlabel("rfeLabel")
                .setColor(0)
                .setFont(createFont(font_type,font_size))
                ;

  frgLabel = cp5.addTextlabel("frgLabel")
                .setColor(0)
                .setFont(createFont(font_type,font_size))
                ;


  bmsVoltageLabel = cp5.addTextlabel("bmsVoltageLabel")
                .setColor(0)
                .setFont(createFont(font_type,font_size))
                ;
            
  bmsTempLabel  = cp5.addTextlabel("bmsTempLabel")
                       .setColor(0)
                       .setFont(createFont(font_type,font_size))
                       ;

  bmsMinTemp = cp5.addTextlabel("bmsMinTemp")
                   .setColor(0)
                   .setFont(createFont(font_type,font_size))
                   ;

  bmsMaxTemp = cp5.addTextlabel("bmsMaxTemp")
                      .setColor(0)
                      .setFont(createFont(font_type,font_size))
                      ;

  bmsStatus = cp5.addTextlabel("bmsStatus")
                      .setColor(0)
                      .setFont(createFont(font_type,font_size))
                      ;

  batteryFaultLabel = cp5.addTextlabel("batteryFaultLabel")
                .setColor(0)
                .setFont(createFont(font_type,font_size))
                ;

  isolationFaultLabel = cp5.addTextlabel("isolationFaultLabel")
                .setColor(0)
                .setFont(createFont(font_type,font_size))
                ;

  aveThrottleLabel = cp5.addTextlabel("aveThrottleLabel")
                      .setColor(0)
                      .setFont(createFont(font_type,font_size))
                      ;

  lvBatteryLabel = cp5.addTextlabel("lvBatteryLabel")
                      .setColor(0)
                      .setFont(createFont(font_type,font_size))
                      ;

  hvLabel = cp5.addTextlabel("hvLabel")
                .setColor(0)
                .setFont(createFont(font_type,font_size))
                ;

  tsaLabel = cp5.addTextlabel("tsaLabel")
                .setColor(0)
                .setFont(createFont(font_type,font_size))
                ;

  relayLabel = cp5.addTextlabel("relayLabel")
                .setColor(0)
                .setFont(createFont(font_type,font_size))
                ;

  carStateLabel = cp5.addTextlabel("carStateLabel")
                .setColor(0)
                .setFont(createFont(font_type,font_size))
                ;
  String filename = String.format("logs/Test (%02d.%02d.%02d - %02d:%02d:%02d).csv", hour(),minute(),second(),year(),month(),day());
  // String filename = "test.csv";
  output = createWriter(filename);

  String firstLine = "TIME,RPM,TORQUE,MOTOR TEMP,MC TEMP,MC VOLTAGE,MC CURRENT,RFE,FRG,PACK VOLTAGE,BATTERY AVERAGE TEMPERATURE,BATTERY TEMP MIN,BATTERY TEMP MAX,BATTERY STATUS,BFAULT,IFAULT,AVETHROTTLE,LV,HV,TSA,SHUTDOWN RELAY,CAR STATE\n";
  output.print(firstLine);

  // start serial communication
  if (!mockupSerial) {
    println(Serial.list());
    String serialPortName = Serial.list()[2];
    serialPort = new Serial(this, Serial.list()[2], 115200);
  }
  else
    serialPort = null;
}

String inBuffer; // holds serial message
String toWrite;
void draw() {
  if(mockupSerial || serialPort.available() > 0) {
    if(mockupSerial){
        inBuffer = mockupSerialFunction();
    }
    else {
      inBuffer = serialPort.readStringUntil('\n');      
    }

    if (inBuffer != null) {
      now = millis();
      seconds = now/1000;
      millis = now-1000*seconds;
      toWrite = String.valueOf(seconds) + "." + String.valueOf(millis) + "," + inBuffer;
      values.add(toWrite);

      // split the string at delimiter (space)
      String[] nums = split(inBuffer, ',');

      String[] lineVariables = new String[3];

      if (nums.length == 21) {
        background(255);
        drawTopValues(nums);
        drawBotValues(nums);
        drawLeftValues(nums);
        // drawRightValues(nums);

        // drawGraph(nums);
        lineVariables[0] = nums[0];
        lineVariables[1] = nums[1];
        lineVariables[2] = nums[2];
        int numberOfInvisibleLineGraphs = 0;
        for (i=0; i<lineVariables.length; i++) {
          if (int(getPlotterConfigString("lgVisible"+(i+1))) == 0) {
            numberOfInvisibleLineGraphs++;
          }
        }

        // build the arrays for bar charts and line graphs
        for (i=0; i<lineVariables.length; i++) {
          // update line graph
          try {
            if (i<lineGraphValues.length) {
              for (int k=0; k<lineGraphValues[i].length-1; k++) {
                lineGraphValues[i][k] = lineGraphValues[i][k+1];
              }
              lineGraphValues[i][lineGraphValues[i].length-1] = float(lineVariables[i])*float(getPlotterConfigString("lgMultiplier"+(i+1)));
            }
          }
          catch (Exception e) {
          }
        }
      }
    }
    LineGraph.DrawAxis();
    for (int i=0;i<lineGraphValues.length; i++) {
      LineGraph.GraphColor = graphColors[i];
      if (int(getPlotterConfigString("lgVisible"+(i+1))) == 1)
        LineGraph.LineGraph(lineGraphSampleNumbers, lineGraphValues[i]);
    }
  }
}

void keyPressed() {
  if(key == 27){
    for(String x : values) {
        String[] temp = x.split(",");
        if (temp.length == 22)
          output.print(x);
    }
    output.flush();
    output.close();
    exit();
  }
}

void setChartSettings() {
  LineGraph.xLabel=" Samples ";
  LineGraph.yLabel="Value";
  LineGraph.Title="";  
  LineGraph.xDiv=20;  
  LineGraph.xMax=0; 
  LineGraph.xMin=-100;  
  LineGraph.yMax=int(getPlotterConfigString("lgMaxY")); 
  LineGraph.yMin=int(getPlotterConfigString("lgMinY"));
}

void drawGraph(String nums[]) {
  int variable_box_width = 900;
  int variable_box_height = 502;
  int start_x = 10 + 120 + 10;
  int start_y = 10 + 50 + 63;

  rect(start_x, start_y, variable_box_width,  variable_box_height);
}

void drawTopValues(String nums[]) {
  int variable_box_width = 120;
  int variable_box_height = 50;
  int start_x = 10;
  int start_y = 10;
  int margin_x = 10;

  rpmLabel.setText("RPM\n"+nums[0])
          .setPosition(start_x,start_y);

  torqueLabel.setText("Torque\n"+nums[1]+"%")
             .setPosition(start_x + (variable_box_width + margin_x) * 1,start_y)
             ;
          
  motorTempLabel.setText("Motor Temp\n"+nums[2])
                .setPosition(start_x + (variable_box_width + margin_x) * 2,start_y)
                ;
          
  mcTempLabel.setText("MC Temp\n"+nums[3])
                .setPosition(start_x + (variable_box_width + margin_x) * 3,start_y)
                ;
          
  mcVoltageLabel.setText("MC Voltage\n"+nums[4])
                .setPosition(start_x + (variable_box_width + margin_x) * 4,start_y)
                ;
          
  mcCurrentLabel.setText("MC Current\n"+nums[5])
                .setPosition(start_x + (variable_box_width + margin_x) * 5,start_y)
                ;

  if(nums[6].equals("1")){
    rfeLabel.setText("RFE\nON");
  }
  else if(nums[6].equals("0")) {
    rfeLabel.setText("RFE\nOFF");
  }
  rfeLabel.setPosition(start_x + (variable_box_width + margin_x) * 6,start_y);


  if(nums[7].equals("1")){
    frgLabel.setText("FRG\nON");
  }
  else if(nums[7].equals("0")) {
  // else{
    frgLabel.setText("FRG\nOFF");
  }
  frgLabel.setPosition(start_x + (variable_box_width + margin_x) * 7,start_y);

  rect(start_x + (variable_box_width + margin_x) * 0, start_y, variable_box_width,  variable_box_height);
  rect(start_x + (variable_box_width + margin_x) * 1, start_y,  variable_box_width, variable_box_height);
  rect(start_x + (variable_box_width + margin_x) * 2, start_y,  variable_box_width, variable_box_height);
  rect(start_x + (variable_box_width + margin_x) * 3, start_y,  variable_box_width, variable_box_height);
  rect(start_x + (variable_box_width + margin_x) * 4, start_y,  variable_box_width, variable_box_height);
  rect(start_x + (variable_box_width + margin_x) * 5, start_y,  variable_box_width, variable_box_height);
  
  if(nums[6].equals("1")){
    fill(38, 166, 91);
  }
  else if(nums[6].equals("0")) {
    fill(242, 38, 19);
  }
  rect(start_x + (variable_box_width + margin_x) * 6, start_y,  variable_box_width, variable_box_height);
  fill(255,255,255);

  if(nums[7].equals("1")){
    fill(38, 166, 91);
  }
  else if(nums[7].equals("0")) {
    fill(242, 38, 19);
  }  
  rect(start_x + (variable_box_width + margin_x) * 7, start_y,  variable_box_width, variable_box_height);
  fill(255,255,255);
}

void drawBotValues(String nums[]) {
  int variable_box_width = 120;
  int variable_box_height = 50;
  int start_x = 10;
  int start_y = window_height - variable_box_height - 10;
  int margin_x = 10;

  bmsVoltageLabel.setText("Pack Voltage\n"+nums[8])
                 .setPosition(start_x,start_y);
            
  bmsTempLabel.setText("Batt Temp\n"+nums[9])
              .setPosition(start_x + (variable_box_width + margin_x) * 1,start_y);

  bmsMinTemp.setText("Min Temp\n"+nums[10])
            .setPosition(start_x + (variable_box_width + margin_x) * 2,start_y);

  bmsMaxTemp.setText("Max Temp\n"+nums[11])
            .setPosition(start_x + (variable_box_width + margin_x) * 3,start_y);

  bmsStatus.setText("BMS Status\n"+nums[12])
           .setPosition(start_x + (variable_box_width + margin_x) * 4,start_y);

  if(nums[13].equals("1")){
    batteryFaultLabel.setText("Batt Fault\nON");
  }
  else if(nums[13].equals("0")) {
    batteryFaultLabel.setText("Batt Fault\nOFF");
  }
  batteryFaultLabel.setPosition(start_x + (variable_box_width + margin_x) * 5,start_y);

  if(nums[14].equals("1")){
    isolationFaultLabel.setText("Iso Fault\nON");
  }
  else if(nums[14].equals("0")) {
  // else{
    isolationFaultLabel.setText("Iso Fault\nOFF");
  }
  isolationFaultLabel.setPosition(start_x + (variable_box_width + margin_x) * 6,start_y);


  aveThrottleLabel.setText("Ave Throttle\n"+nums[15])
                  .setPosition(start_x + (variable_box_width + margin_x) * 7,start_y);

  rect(start_x, start_y, variable_box_width,  variable_box_height);
  rect(start_x + (variable_box_width + margin_x) * 1, start_y,  variable_box_width, variable_box_height);
  rect(start_x + (variable_box_width + margin_x) * 2, start_y,  variable_box_width, variable_box_height);
  rect(start_x + (variable_box_width + margin_x) * 3, start_y,  variable_box_width, variable_box_height);
  rect(start_x + (variable_box_width + margin_x) * 4, start_y,  variable_box_width, variable_box_height);

  if(nums[13].equals("1")){
    fill(38, 166, 91);
  }
  else if(nums[13].equals("0")) {
    fill(242, 38, 19);
  }
  rect(start_x + (variable_box_width + margin_x) * 5, start_y,  variable_box_width, variable_box_height);
  fill(255,255,255);

  if(nums[14].equals("1")){
    fill(38, 166, 91);
  }
  else if(nums[14].equals("0")) {
    fill(242, 38, 19);
  }  
  rect(start_x + (variable_box_width + margin_x) * 6, start_y,  variable_box_width, variable_box_height);
  fill(255,255,255);

  rect(start_x + (variable_box_width + margin_x) * 7, start_y,  variable_box_width, variable_box_height);
}

void drawLeftValues(String nums[]) {
  int variable_box_width = 120;
  int variable_box_height = 50;
  int start_x = 10;
  int margin_y = 63;
  int start_y = variable_box_height + 10 + margin_y;

  
  lvBatteryLabel.setText("LV\n"+nums[16])
                .setPosition(start_x,start_y + (variable_box_height + margin_y) * 0);

  hvLabel.setText("HV\n"+nums[17])
         .setPosition(start_x,start_y + (variable_box_height + margin_y) * 1);


  if(nums[18].equals("1")){
    tsaLabel.setText("TSA\nON");
  }
  else if(nums[18].equals("0")) {
    tsaLabel.setText("TSA\nOFF");
  }
  tsaLabel.setPosition(start_x,start_y + (variable_box_height + margin_y) * 2);

  if(nums[19].equals("1")){
    relayLabel.setText("Relay\nON");
  }
  else if(nums[19].equals("0")) {
  // else{
    relayLabel.setText("Relay\nOFF");
  }
  relayLabel.setPosition(start_x,start_y + (variable_box_height + margin_y) * 3);


  if(nums[20].equals("0\n")){
    carStateLabel.setText("Car State\nIDLE");
  }
  else if(nums[20].equals("1\n")) {
    carStateLabel.setText("Car State\nDRIVE");
    fill(38, 166, 91);
  }
  else if(nums[20].equals("2\n")) {
    carStateLabel.setText("Car State\nFAULT");
    fill(242, 38, 19);
  }
  else {
    carStateLabel.setText("Car State\n"+nums[20]);
  }
  carStateLabel.setPosition(start_x,start_y + (variable_box_height + margin_y) * 4);
  rect(start_x, start_y + (variable_box_height + margin_y) * 4,  variable_box_width, variable_box_height);
  fill(255,255,255);

  rect(start_x, start_y, variable_box_width,  variable_box_height);
  rect(start_x, start_y + (variable_box_height + margin_y) * 1,  variable_box_width, variable_box_height);


  if(nums[18].equals("1")){
    fill(38, 166, 91);
  }
  else if(nums[18].equals("0")) {
    fill(242, 38, 19);
  }
  rect(start_x, start_y + (variable_box_height + margin_y) * 2,  variable_box_width, variable_box_height);
  fill(255,255,255);

  if(nums[19].equals("1")){
    fill(38, 166, 91);
  }
  else if(nums[19].equals("0")) {
    fill(242, 38, 19);
  }
  rect(start_x, start_y + (variable_box_height + margin_y) * 3,  variable_box_width, variable_box_height);
  fill(255,255,255);
}

void drawRightValues(String nums[]) {
  int variable_box_width = 120;
  int variable_box_height = 50;
  int start_x = window_width - variable_box_width - 10;
  int start_y = variable_box_height + 10 + 63;
  int margin_y = 63;

  rect(start_x, start_y, variable_box_width,  variable_box_height);
  rect(start_x, start_y + (variable_box_height + margin_y) * 1,  variable_box_width, variable_box_height);
  rect(start_x, start_y + (variable_box_height + margin_y) * 2,  variable_box_width, variable_box_height);
  rect(start_x, start_y + (variable_box_height + margin_y) * 3,  variable_box_width, variable_box_height);
  rect(start_x, start_y + (variable_box_height + margin_y) * 4,  variable_box_width, variable_box_height);
  
  lvBatteryLabel.setText("LV\n"+nums[16])
                .setPosition(start_x,start_y);

  hvLabel.setText("HV\n"+nums[17])
         .setPosition(start_x,start_y + (variable_box_height + margin_y) * 1);

  tsaLabel.setText("TSA\n"+nums[18])
          .setPosition(start_x,start_y + (variable_box_height + margin_y) * 2);

  relayLabel.setText("Relay\n"+nums[19])
            .setPosition(start_x,start_y + (variable_box_height + margin_y) * 3);

  carStateLabel.setText("Car State\n"+nums[20])
               .setPosition(start_x,start_y + (variable_box_height + margin_y) * 4);
}

// handle gui actions
void controlEvent(ControlEvent theEvent) {
  if (theEvent.isAssignableFrom(Textfield.class) || theEvent.isAssignableFrom(Toggle.class) || theEvent.isAssignableFrom(Button.class)) {
    String parameter = theEvent.getName();
    String value = "";
    if (theEvent.isAssignableFrom(Textfield.class))
      value = theEvent.getStringValue();
    else if (theEvent.isAssignableFrom(Toggle.class) || theEvent.isAssignableFrom(Button.class))
      value = theEvent.getValue()+"";

    plotterConfigJSON.setString(parameter, value);
    saveJSONObject(plotterConfigJSON, topSketchPath+"/plotter_config.json");
  }
  setChartSettings();
}

// get gui settings from settings file
String getPlotterConfigString(String id) {
  String r = "";
  try {
    r = plotterConfigJSON.getString(id);
  } 
  catch (Exception e) {
    r = "";
  }
  return r;
}
