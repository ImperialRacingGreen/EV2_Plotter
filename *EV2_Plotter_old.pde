import java.util.*;

import java.awt.Frame;
import java.awt.BorderLayout;
import controlP5.*; // http://www.sojamo.de/libraries/controlP5/
import processing.serial.*;

String variables[] = { 
  "RPM",
  "SPEED",
  "TORQUE",
  "AIR TEMP",
  "MC TEMP",
  "MOTOR TEMP",
  "MC VOLTAGE",
  "MC CURRENT",
  "MC POWER",
  "MC CORE STATUS",
  "MC ERROR",
  "MC MESSAGE COUNT",
  "RFE", 
  "FRG",
  "MC GO",
  "BMS VOLTAGE",
  "BMS MIN VOLTAGE",
  "BMS MAX VOLTAGE",
  "BMS CURRENT",
  "BMS SOC",
  "BMS TEMP",
  "BMS MINTEMP",
  "BMS MAXTEMP",
  "BMS STATUS",
  "BMS STATE",
  "BMS CAPACITY",
  "CAR_STATE",
  "BATT FAULT",
  "ISO FAULT",
  "THROTTLE 1",
  "THROTTLE 2",
  "AVE THROTTLE",
  "BRAKE",
  "LV",
  "HV",
  "ERROR",
  "TSA",
  "RELAY",
  "HIGH CURRENT",
  "INSULATION PWM",
  "START SWITCH"
};

boolean mockupSerial = true;
Serial serialPort; // Serial port object
ControlP5 cp5;
JSONObject plotterConfigJSON;
String topSketchPath = "";

int BOX_WIDTH = 140;
int BOX_HEIGHT = 50;
int BOX_MARGIN_X = 5;
int BOX_MARGIN_Y = 5;
int NUM_OF_BOX = 11;
int NUM_OF_ROW = 6;

// int GRAPH_WIDTH = window_width - BOX_MARGIN_X * 2;
// int GRAPH_HEIGHT = window_height - (BOX_HEIGHT + BOX_MARGIN_Y) * NUM_OF_ROW - BOX_MARGIN_Y * 2;
int GRAPH_WIDTH = 1055 - BOX_WIDTH;
int GRAPH_HEIGHT = 600;
int GRAPH_POS_X = BOX_MARGIN_X;
int GRAPH_POS_Y = (BOX_HEIGHT + BOX_MARGIN_Y) * NUM_OF_ROW + BOX_MARGIN_Y;

int window_width = BOX_WIDTH * NUM_OF_BOX + BOX_MARGIN_X * 3;
// int window_height = (BOX_HEIGHT + BOX_MARGIN_Y)*NUM_OF_ROW + GRAPH_HEIGHT + 500;
int window_height = 1000;
int font_size = 20;
String font_type = "Verdana";

String graphLines[] = {
  "RPM",
  "TORQUE",
  "MOTORTEMP"
};

// Labels for Variables
List<Textlabel> variableLabels = new ArrayList<Textlabel>();
List<Textlabel> graphLinesLabel = new ArrayList<Textlabel>();

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
int error_x = 96;
int error_y = 59;
Graph LineGraph = new Graph(error_x + GRAPH_POS_X, error_y + GRAPH_POS_Y, GRAPH_WIDTH, GRAPH_HEIGHT, color (255));
float[][] lineGraphValues = new float[3][100];
float[] lineGraphSampleNumbers = new float[100];
color[] graphColors = new color[3];

int col = color(0);
CheckBox checkbox;

void setup() {
  cp5 = new ControlP5(this);

  labelSetup();
  windowSetup();
  fileSetup();

  
  // start serial communication
  if (!mockupSerial) {
    println(Serial.list());
    String serialPortName = Serial.list()[1];
    serialPort = new Serial(this, Serial.list()[1], 115200);
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
      inBuffer = inBuffer.replace("#", "");
      now = millis();
      seconds = now/1000;
      millis = now-1000*seconds;
      toWrite = String.valueOf(seconds) + "." + String.format("%03d", millis) + "," + inBuffer;
      values.add(toWrite);

      // split the string at delimiter (space)
      String[] nums = split(inBuffer, ',');

      String[] lineVariables = new String[3];

      if (nums.length == variables.length) {
        background(0);
        drawMCValues(nums);
        drawBMSValues(nums);
        drawCarValues(nums);
        
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

  // pushMatrix();
  
  // if(toggleValue==true) {
  //   // fill(255,255,220);
  // } else {
  //   // fill(128,128,110);
  // }
  
  // popMatrix();
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
  topSketchPath = sketchPath("");
  plotterConfigJSON = loadJSONObject(topSketchPath+"/plotter_config.json");

  // gui
  int x = 180;
  int y = 135;

  // cp5.addTextfield("lgMaxY").setPosition(x, y).setText(getPlotterConfigString("lgMaxY")).setWidth(40).setAutoClear(false);
  // cp5.addTextfield("lgMinY").setPosition(x, y = y + 450).setText(getPlotterConfigString("lgMinY")).setWidth(40).setAutoClear(false);
  
  setChartSettings();
  // build x axis values for the line graph
  for (int i=0; i<lineGraphValues.length; i++) {
    for (int k=0; k<lineGraphValues[0].length; k++) {
      lineGraphValues[i][k] = 0;
      if (i==0)
        lineGraphSampleNumbers[k] = k;
    }
  }
}

void fileSetup() {
  String filename = String.format("logs/Test (%02d.%02d.%02d on %02d-%02d-%02d).csv", hour(),minute(),second(),year(),month(),day());
  output = createWriter(filename);

  String firstLine = "TIME,";

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

        String[] nums = split(x, ',');
        if (nums.length == variables.length + 1) {
          output.println(x); 
        }
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

void drawValues(String nums[], int start_index, int end_index, int start_x, int start_y, int margin_x, int margin_y, int hor, int ver){
  for (int i = start_index; i <= end_index; i++) {
    String value = nums[i];

    String label = variables[i] + "\n" + value;
    temp = variableLabels.get(i);
    temp.setText(label);
    temp.setPosition(
      start_x + (BOX_WIDTH + margin_x) * (i - start_index) * hor,
      start_y + (BOX_HEIGHT + margin_y) * (i - start_index) * ver
    );
    stroke(255);

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

  drawValues(nums,26,35,start_x,start_y,margin_x,margin_y,1,0);
  drawValues(nums,36,40,start_x,start_y+BOX_HEIGHT,margin_x,margin_y,1,0);
}

void drawMCValues(String nums[]) {
  MCLabel.setText("Motor\nController");
  MCLabel.setPosition(BOX_MARGIN_X,BOX_MARGIN_Y+BOX_HEIGHT+BOX_MARGIN_Y);

  int start_x = BOX_MARGIN_X + BOX_WIDTH + BOX_MARGIN_X;
  int start_y = BOX_MARGIN_Y + (BOX_HEIGHT + BOX_MARGIN_Y) * 2;
  int margin_x = 0;
  int margin_y = 0;

  drawValues(nums,0,9,start_x,start_y,margin_x,margin_y,1,0);
  drawValues(nums,10,14,start_x,start_y + BOX_HEIGHT,margin_x,margin_y,1,0);
}

void drawBMSValues(String nums[]) {
  BMSLabel.setText("BMS");
  BMSLabel.setPosition(BOX_MARGIN_X,BOX_MARGIN_Y+(BOX_HEIGHT+BOX_MARGIN_Y)*2);

  int start_x = BOX_MARGIN_X + BOX_WIDTH + BOX_MARGIN_X;
  int start_y = BOX_MARGIN_Y + (BOX_HEIGHT + BOX_MARGIN_Y) * 4;
  int margin_x = 0;
  int margin_y = 0;

  drawValues(nums,15,24,start_x,start_y,margin_x,margin_y,1,0);
  drawValues(nums,25,25,start_x,start_y+BOX_HEIGHT,margin_x,margin_y,1,0);
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

  if (theEvent.isFrom(checkbox)) {
    // myColorBackground = 0;
    print("got an event from "+checkbox.getName()+"\t\n");
    // checkbox uses arrayValue to store the state of 
    // individual checkbox-items. usage:
    println(checkbox.getArrayValue());
    int col = 0;
    for (int i=0;i<checkbox.getArrayValue().length;i++) {
      int n = (int)checkbox.getArrayValue()[i];
      print(n);
      if(n==1) {
        // myColorBackground += checkbox.getItem(i).internalValue();
      }
    }
    println();    
  }
}

void checkBox(float[] a) {
  println(a);
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