import java.util.*;

import java.awt.Frame;
import java.awt.BorderLayout;
import controlP5.*; // http://www.sojamo.de/libraries/controlP5/
import processing.serial.*;

String variables[] = { 
  "RPM",
  "TORQUE",
  "MOTOR TEMP",
  "MC TEMP",
  "MC VOLTAGE",
  "MC CURRENT",
  "MC POWER",
  "RFE",
  "FRG",
  "BMS VOLTAGE",
  "BMS TEMP",
  "BMS MINTEMP",
  "BMS MAXTEMP",
  "BMS STATUS",
  "BATT FAULT",
  "ISO FAULT",
  "AVE THROTTLE",
  "BRAKE",
  "LV",
  "HV",
  "TSA",
  "RELAY",
  "CAR_STATE"
};

boolean mockupSerial = true;
Serial serialPort; // Serial port object
ControlP5 cp5;
JSONObject plotterConfigJSON;
String topSketchPath = "";

int window_width = 120 * 10 + 5 * 3;
int window_height = 750;
int font_size = 12;
String font_type = "Verdana";

int BOX_WIDTH = 120;
int BOX_HEIGHT = 35;
int BOX_MARGIN_X = 5;
int BOX_MARGIN_Y = 5;
// Labels for Variables
List<Textlabel> variableLabels = new ArrayList<Textlabel>();
Textlabel temp;

Textlabel MCLabel;
Textlabel BMSLabel;
Textlabel CarLabel;

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
  cp5 = new ControlP5(this);

  labelSetup();
  windowSetup();
  //windowSetup2();  
  fileSetup();
  
  // start serial communication
  if (!mockupSerial) {
    println(Serial.list());
    String serialPortName = Serial.list()[2];
    serialPort = new Serial(this, Serial.list()[2], 9600);
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
      inBuffer = serialPort.readStringUntil('#');      
    }

    if (inBuffer != null) {
      inBuffer = inBuffer.replace("@", "");
      inBuffer = inBuffer.replace("\n", "");
      now = millis();
      seconds = now/1000;
      millis = now-1000*seconds;
      toWrite = String.valueOf(seconds) + "." + String.valueOf(millis) + "," + inBuffer;
      values.add(toWrite);

      // split the string at delimiter (space)
      String[] nums = split(inBuffer, ',');

      String[] lineVariables = new String[3];

      if (nums.length == 23) {
        background(0);
        drawMCValues(nums);
        drawBMSValues(nums);
        drawCarValues(nums);

        // drawGraph(nums);
        // lineVariables[0] = nums[0];
        // lineVariables[1] = nums[1];
        // lineVariables[2] = nums[2];
        // int numberOfInvisibleLineGraphs = 0;
        // for (i=0; i<lineVariables.length; i++) {
        //   if (int(getPlotterConfigString("lgVisible"+(i+1))) == 0) {
        //     numberOfInvisibleLineGraphs++;
        //   }
        // }

        // // build the arrays for bar charts and line graphs
        // for (i=0; i<lineVariables.length; i++) {
        //   // update line graph
        //   try {
        //     if (i<lineGraphValues.length) {
        //       for (int k=0; k<lineGraphValues[i].length-1; k++) {
        //         lineGraphValues[i][k] = lineGraphValues[i][k+1];
        //       }
        //       lineGraphValues[i][lineGraphValues[i].length-1] = float(lineVariables[i])*float(getPlotterConfigString("lgMultiplier"+(i+1)));
        //     }
        //   }
        //   catch (Exception e) {
        //   }
        // }
      }
    }
    
    // LineGraph.DrawAxis();
    // for (int i=0;i<lineGraphValues.length; i++) {
    //   LineGraph.GraphColor = graphColors[i];
    //   if (int(getPlotterConfigString("lgVisible"+(i+1))) == 1)
    //     LineGraph.LineGraph(lineGraphSampleNumbers, lineGraphValues[i]);
    // }
  }
}

void labelSetup() {
  for (int i = 0; i < variables.length; i++) {
    temp = cp5.addTextlabel(variables[i])
                .setColor(255)
                .setFont(createFont(font_type,font_size))
                ;
    variableLabels.add(temp);
  }
  MCLabel = cp5.addTextlabel("MC")
                .setColor(255)
                .setFont(createFont(font_type,font_size))
                ;
  BMSLabel = cp5.addTextlabel("BMS")
                .setColor(255)
                .setFont(createFont(font_type,font_size))
                ;
  CarLabel = cp5.addTextlabel("Car")
                .setColor(255)
                .setFont(createFont(font_type,font_size))
                ;
}

void windowSetup() {
  frame.setTitle("EV2 DYNO");

  size(window_width, window_height);
  graphColors[0] = color(38, 166, 91);
  graphColors[1] = color(248, 148, 6);
  graphColors[2] = color(207, 0, 15);

  // settings save file
  topSketchPath = sketchPath;
  plotterConfigJSON = loadJSONObject(topSketchPath+"/plotter_config.json");

  // gui
  int x = 180;
  int y = 135;

  // cp5.addTextfield("lgMaxY").setPosition(x, y).setText(getPlotterConfigString("lgMaxY")).setWidth(40).setAutoClear(false);
  // cp5.addTextfield("lgMinY").setPosition(x, y = y + 450).setText(getPlotterConfigString("lgMinY")).setWidth(40).setAutoClear(false);
  
  // setChartSettings();
  // // build x axis values for the line graph
  // for (int i=0; i<lineGraphValues.length; i++) {
  //   for (int k=0; k<lineGraphValues[0].length; k++) {
  //     lineGraphValues[i][k] = 0;
  //     if (i==0)
  //       lineGraphSampleNumbers[k] = k;
  //   }
  // }

  // x = (120 + 10) * 9 + 10;
  // y = 10;

  // cp5.addTextlabel("label").setText("on/off").setPosition(x=x, y=y).setColor(0);
  // cp5.addToggle("lgVisible1").setPosition(x=x, y=y+15).setValue(int(getPlotterConfigString("lgVisible1"))).setMode(ControlP5.SWITCH).setColorActive(graphColors[0]);
  // cp5.addToggle("lgVisible2").setPosition(x=x, y=y+35).setValue(int(getPlotterConfigString("lgVisible2"))).setMode(ControlP5.SWITCH).setColorActive(graphColors[0]);
  // cp5.addToggle("lgVisible3").setPosition(x=x, y=y+35).setValue(int(getPlotterConfigString("lgVisible3"))).setMode(ControlP5.SWITCH).setColorActive(graphColors[0]);
  
  // x += 45;
  // y = 10;

  // cp5.addTextlabel("multipliers").setText("multipliers").setPosition(x=x, y=y).setColor(0);
  // cp5.addTextfield("1").setPosition(x=x, y=y+15).setText(getPlotterConfigString("lgMultiplier1")).setColorCaptionLabel(0).setWidth(40).setAutoClear(false);
  // cp5.addTextfield("2").setPosition(x=x, y=y+35).setText(getPlotterConfigString("lgMultiplier2")).setColorCaptionLabel(0).setWidth(40).setAutoClear(false);
  // cp5.addTextfield("3").setPosition(x, y=y+35).setText(getPlotterConfigString("lgMultiplier3")).setColorCaptionLabel(0).setWidth(40).setAutoClear(false);
}

void fileSetup() {
  String filename = String.format("logs/Test (%02d.%02d.%02d on %02d-%02d-%02d).csv", hour(),minute(),second(),year(),month(),day());
  output = createWriter(filename);

  String firstLine = String.format("Data for Test at %02d:%02d:%02d on %02d-%02d-%02d \n\n", hour(),minute(),second(),year(),month(),day());
  output.print(firstLine);

  firstLine = "TIME,";

  for (String variable : variables) {
    firstLine += variable;
    firstLine += ",";
  }

  firstLine += "\n";

  output.print(firstLine);
}

void keyPressed() {
  if(key == 27){
    for(String x : values) {
        output.println(x);
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

void drawValues(String nums[], int start_index, int end_index, int start_x, int start_y, int margin_x, int margin_y, int hor, int ver){
  for (int i = start_index; i <= end_index; i++) {
    // switch case to modify label and label colour
    String label = variables[i] + "\n" + nums[i];
    temp = variableLabels.get(i);
    temp.setText(label);
    temp.setPosition(
      start_x + (BOX_WIDTH + margin_x) * (i - start_index) * hor,
      start_y + (BOX_HEIGHT + margin_y) * (i - start_index) * ver
    );
    stroke(255);
    noFill();
    rect(
      start_x + (BOX_WIDTH + margin_x) * (i - start_index) * hor,
      start_y + (BOX_HEIGHT + margin_y) * (i - start_index) * ver, 
      BOX_WIDTH,  BOX_HEIGHT
    );
  }
}

void drawCarValues(String nums[]) {
  CarLabel.setText("Car");
  CarLabel.setPosition(BOX_MARGIN_X,BOX_MARGIN_Y);
  
  int start_x = BOX_MARGIN_X + BOX_WIDTH + BOX_MARGIN_X;
  int start_y = BOX_MARGIN_Y;
  
  int margin_x = 0;
  int margin_y = 0;

  drawValues(nums,14,22,start_x,start_y,margin_x,margin_y,1,0);
}

void drawMCValues(String nums[]) {
  MCLabel.setText("Motor\nController");
  MCLabel.setPosition(BOX_MARGIN_X,BOX_MARGIN_Y+BOX_HEIGHT+BOX_MARGIN_Y);

  int start_x = BOX_MARGIN_X + BOX_WIDTH + BOX_MARGIN_X;
  int start_y = BOX_MARGIN_Y + BOX_HEIGHT + BOX_MARGIN_Y;
  int margin_x = 0;
  int margin_y = 0;

  drawValues(nums,0,8,start_x,start_y,margin_x,margin_y,1,0);
}

void drawBMSValues(String nums[]) {
  BMSLabel.setText("BMS");
  BMSLabel.setPosition(BOX_MARGIN_X,BOX_MARGIN_Y+(BOX_HEIGHT+BOX_MARGIN_Y)*2);

  int start_x = BOX_MARGIN_X + BOX_WIDTH + BOX_MARGIN_X;
  int start_y = BOX_MARGIN_Y + (BOX_HEIGHT + BOX_MARGIN_Y) * 2;
  int margin_x = 0;
  int margin_y = 0;

  drawValues(nums,9,13,start_x,start_y,margin_x,margin_y,1,0);
}

void drawRightValues(String nums[]) {
  // int x = 0;
  // int variable_box_width = 120;
  // int variable_box_height = 50;
  // int start_x = window_width - variable_box_width - 10;
  // int start_y = variable_box_height + 10 + 63;
  // int margin_y = 63;

  // rect(start_x, start_y, variable_box_width,  variable_box_height);
  // rect(start_x, start_y + (variable_box_height + margin_y) * 1,  variable_box_width, variable_box_height);
  // rect(start_x, start_y + (variable_box_height + margin_y) * 2,  variable_box_width, variable_box_height);
  // rect(start_x, start_y + (variable_box_height + margin_y) * 3,  variable_box_width, variable_box_height);
  // rect(start_x, start_y + (variable_box_height + margin_y) * 4,  variable_box_width, variable_box_height);
  
  // lvBatteryLabel.setText("LV\n"+nums[17])
  //               .setPosition(start_x,start_y);

  // hvLabel.setText("HV\n"+nums[18])
  //        .setPosition(start_x,start_y + (variable_box_height + margin_y) * 1);

  // tsaLabel.setText("TSA\n"+nums[19])
  //         .setPosition(start_x,start_y + (variable_box_height + margin_y) * 2);

  // relayLabel.setText("Relay\n"+nums[20])
  //           .setPosition(start_x,start_y + (variable_box_height + margin_y) * 3);

  // carStateLabel.setText("Car State\n"+nums[21])
  //              .setPosition(start_x,start_y + (variable_box_height + margin_y) * 4);

  // lvBatteryLabel.setText("LV\n"+nums[18])
  //               .setPosition(start_x,start_y + (variable_box_height + margin_y) * 0);

  // hvLabel.setText("HV\n"+nums[19])
  //        .setPosition(start_x,start_y + (variable_box_height + margin_y) * 1);


  // if(nums[20].equals("1")){
  //   tsaLabel.setText("TSA\nON");
  // }
  // else if(nums[20].equals("0")) {
  //   tsaLabel.setText("TSA\nOFF");
  // }
  // tsaLabel.setPosition(start_x,start_y + (variable_box_height + margin_y) * 2);

  // if(nums[21].equals("1")){
  //   relayLabel.setText("Relay\nON");
  // }
  // else if(nums[21].equals("0")) {
  // // else{
  //   relayLabel.setText("Relay\nOFF");
  // }
  // relayLabel.setPosition(start_x,start_y + (variable_box_height + margin_y) * 3);


  // if(nums[22].equals("0#")){
  //   carStateLabel.setText("Car State\nIDLE");
  // }
  // else if(nums[22].equals("1#")) {
  //   carStateLabel.setText("Car State\nDRIVE");
  //   fill(38, 166, 91);
  // }
  // else if(nums[22].equals("2#")) {
  //   carStateLabel.setText("Car State\nFAULT");
  //   fill(242, 38, 19);
  // }
  // else {
  //   carStateLabel.setText("Car State\n"+nums[22]);
  // }
  // carStateLabel.setPosition(start_x,start_y + (variable_box_height + margin_y) * 4);
  // rect(start_x, start_y + (variable_box_height + margin_y) * 4,  variable_box_width, variable_box_height);
  // fill(255,255,255);

  // rect(start_x, start_y, variable_box_width,  variable_box_height);
  // rect(start_x, start_y + (variable_box_height + margin_y) * 1,  variable_box_width, variable_box_height);


  // if(nums[20].equals("1")){
  //   fill(38, 166, 91);
  // }
  // else if(nums[20].equals("0")) {
  //   fill(242, 38, 19);
  // }
  // rect(start_x, start_y + (variable_box_height + margin_y) * 2,  variable_box_width, variable_box_height);
  // fill(255,255,255);

  // if(nums[21].equals("1")){
  //   fill(38, 166, 91);
  // }
  // else if(nums[21].equals("0")) {
  //   fill(242, 38, 19);
  // }
  // rect(start_x, start_y + (variable_box_height + margin_y) * 3,  variable_box_width, variable_box_height);
  // fill(255,255,255);
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