import java.util.*;

import java.awt.Frame;
import java.awt.BorderLayout;
import controlP5.*; // http://www.sojamo.de/libraries/controlP5/
import processing.serial.*;

//These are all of the variables that are read in from the arduino that need to be displayed
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

//Start a serial communication with the arduino
boolean mockupSerial = true;
Serial serialPort; // Serial port object
ControlP5 cp5;
JSONObject plotterConfigJSON;
String topSketchPath = "";

//Setup box sizes

int BOX_WIDTH = 130;
int BOX_HEIGHT = 50;
int BOX_MARGIN_X = 5;
int BOX_MARGIN_Y = 5;
int NUM_OF_BOX = 11;
int NUM_OF_ROW = 6;

//Setup graph sizes and positions

// int GRAPH_WIDTH = window_width - BOX_MARGIN_X * 2;
// int GRAPH_HEIGHT = window_height - (BOX_HEIGHT + BOX_MARGIN_Y) * NUM_OF_ROW - BOX_MARGIN_Y * 2;
int GRAPH_WIDTH = 1055 - BOX_WIDTH;
int GRAPH_HEIGHT = 600;
int GRAPH_POS_X = BOX_MARGIN_X;
int GRAPH_POS_Y = (BOX_HEIGHT + BOX_MARGIN_Y) * NUM_OF_ROW + BOX_MARGIN_Y;

//Setup the window sizes

int window_width = BOX_WIDTH * NUM_OF_BOX + BOX_MARGIN_X * 3;
// int window_height = (BOX_HEIGHT + BOX_MARGIN_Y)*NUM_OF_ROW + GRAPH_HEIGHT + 500;
int window_height = 1000;
int font_size = 20;
String font_type = "Verdana";

//Create a string to hold all of the graph lines

String graphLines[] = {
  "RPM",
  "SPEED",
  "TORQUE",
  "AIR TEMP",
  "MC TEMP",
  "MOTOR TEMP",
  "MC VOLTAGE",
  "MC CURRENT",
  "MC POWER",
  "BMS VOLTAGE",
  "BMS CURRENT",
  "BMS SOC",
  "BMS TEMP",
  "BMS MINTEMP",
  "BMS MAXTEMP",
  "THROTTLE 1",
  "THROTTLE 2",
  "AVE THROTTLE",
  "BRAKE"
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
float[][] lineGraphValues = new float[4][100];
float[] lineGraphSampleNumbers = new float[100];
color[] graphColors = new color[4];

CheckBox checkbox;
int col = color(0);


//Main setup code - initialises everything
void setup() {
  windowSetup();

 cp5 = new ControlP5(this);
 
  labelSetup();
  fileSetup();
  
  // start serial communication
  if (!mockupSerial) {
    //println(Serial.list());
    String serialPortName = Serial.list()[2];
    serialPort = new Serial(this, Serial.list()[2], 115200);
  }
  else
    serialPort = null;

  //Create a checkbox object to holf all of the checkboxes
  checkbox = cp5.addCheckBox("selectGraphLines")
   .setPosition(window_width - BOX_WIDTH, GRAPH_POS_Y)
   .setSize(20,20)
   .setColorForeground(color(120))
   .setColorActive(color(255))
   .setColorLabel(color(255))
   .setItemsPerRow(1)
   .setSpacingRow(12)
   .addItem("Show RPM", 0)
   .addItem("Show SPEED", 0)
   .addItem("Show TORQUE", 0)
   .addItem("Show MOTORTEMP", 0)
   .addItem("Show AIR TEMP", 0)
   .addItem("Show MC TEMP", 0)
   .addItem("Show MOTOR TEMP", 0)
   .addItem("Show MC VOLTAGE", 0)
   .addItem("Show MC CURRENT", 0)
   .addItem("Show MC POWER", 0)
   .addItem("Show BMS VOLTAGE", 0)
   .addItem("Show BMS CURRENT", 0)
   .addItem("Show BMS SOC", 0)
   .addItem("Show BMS TEMP", 0)
   .addItem("Show BMS MINTEMP", 0)
   .addItem("Show BMS MAXTEMP", 0)
   .addItem("Show THROTTLE 1", 0)
   .addItem("Show THROTTLE 2", 0)
   .addItem("Show AVE THROTTLE", 0)
   .addItem("Show BRAKE", 0)
   ;
}

String inBuffer; // holds serial message
String toWrite;

//Draw the information to the window. New serial data is read in and inputted into the string. The @ startbyte and #stopbyte are removed and a timestamp is added, it is then saved in a file. The string is also split at spaces and inputted into the string[] nums

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

      String[] lineVariables = new String[4];

      //Make sure the correct number of variables have been read in
      if (nums.length == variables.length) {
        background(0);
        drawMCValues(nums);
        drawBMSValues(nums);
        drawCarValues(nums);
        
        drawGraph(nums);
        drawRightBar();
        
        //Add the variables to be drawn to the graph to the lines variable array
        lineVariables[0] = nums[0];
        lineVariables[1] = nums[1];
        lineVariables[2] = nums[2];
        //lineVariables[3] = nums[3];
        
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
             if ((i<lineGraphValues.length) && ((int)checkbox.getArrayValue()[i] == 1)){
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

//Setup the variables for the labels to be drawn
void labelSetup() {
  for (int i = 0; i < variables.length; i++) {
    temp = cp5.addTextlabel(variables[i])
                .setColor(255)
                .setFont(createFont(font_type,font_size))
                ;
    variableLabels.add(temp);
  }
  // for(int i = 0; i < 3; i++) {
  //   temp = cp5.addTextlabel(graphLines[i] + "line")
  //               .setColor(255)
  //               .setFont(createFont(font_type,font_size))
  //               ;
  //   graphLinesLabel.add(temp);
  // }
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



//Setup the display window for the chart and values
void windowSetup() {
  surface.setTitle("EV2 DYNO");
  surface.setSize(window_width, window_height);
  graphColors[0] = color(38, 166, 91);
  graphColors[1] = color(248, 148, 6);
  graphColors[2] = color(207, 0, 15);
  //graphColors[3] = color(0,0,255);

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

//Setup the file to store the data in, data is stored as an entry with a timestamp
void fileSetup() {
  String filename = String.format("logs/Test (%02d.%02d.%02d on %02d-%02d-%02d).csv", hour(),minute(),second(),year(),month(),day());
  output = createWriter(filename);

  // String firstLine = String.format("Data for Test at %02d:%02d:%02d on %02d-%02d-%02d \n\n", hour(),minute(),second(),year(),month(),day());
  // output.print(firstLine);

  String firstLine = "TIME,";

  for (String variable : variables) {
    firstLine += variable;
    firstLine += ",";
  }

  firstLine += "\n";

  output.print(firstLine);
}

//If the escape key is pressed, exit the program and clear the buffers
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

//Set the settings for the graph
void setChartSettings() {
  LineGraph.xLabel=" Samples ";
  LineGraph.yLabel="Value";
  LineGraph.Title="";  
  LineGraph.xDiv=20;  
  LineGraph.xMax=0; 
  LineGraph.xMin=-100;  
  LineGraph.yMax=int(getPlotterConfigString("lgMaxY")); 
  LineGraph.yMin=int(getPlotterConfigString("lgMinY"));
  // LineGraph.yMin=0;
}

void drawGraph(String nums[]) {
  // int graph_box_width = window_width - 5*2;
  // int graph_box_height = window_height - BOX_HEIGHT*3 - 5*5;
  // int start_x = 5;
  // int start_y = BOX_HEIGHT*3 + 5*4;
  // noFill();
  // rect(start_x, start_y, graph_box_width,  graph_box_height);
}

// Draw the bar on the right hand side of the screen
void drawRightBar() {  
  // graphColors[0] = color(38, 166, 91);
  // graphColors[1] = color(248, 148, 6);
  // graphColors[2] = color(207, 0, 15);

  // 0 - RPM
  // 1 - TORQUE
  // 2 - MOTOR TEMP
  int temp_start_x = 0;
  int temp_start_y = 0;

  for (int i=0; i<graphLinesLabel.size(); i++) {
    String label = graphLines[i];
    temp = graphLinesLabel.get(i);
    temp.setText(label);
    temp.setPosition(
      window_width - BOX_WIDTH,
      error_y + GRAPH_POS_Y + i*20
    );

    if (graphLines[i].equals("RPM")){
      temp.setColorValue(#26A65B);
    }
    else if (graphLines[i].equals("TORQUE")){
      temp.setColorValue(#F89406);
    }
    else if (graphLines[i].equals("MOTORTEMP")){
      temp.setColorValue(#CF000F);
    }
    else if(graphLines[i].equals("SPEED")){
      temp.setColorValue(#0000FF);
    }
    else {
      temp.setColor(255);
    }
  }
}

//Draw the boxes to contain the values and insert the value into them.
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

//Draw the boxes containing the car values
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

//Draw the boxes containing the MC values
void drawMCValues(String nums[]) {
  MCLabel.setText("Motor\nController");
  MCLabel.setPosition(BOX_MARGIN_X,BOX_MARGIN_Y+BOX_HEIGHT+BOX_MARGIN_Y);

  int start_x = BOX_MARGIN_X + BOX_WIDTH + BOX_MARGIN_X;
  int start_y = BOX_MARGIN_Y + (BOX_HEIGHT + BOX_MARGIN_Y) * 2;
  int margin_x = 0;
  int margin_y = 0;

  drawValues(nums,0,9,start_x,start_y,margin_x,margin_y,1,0);
  drawValues(nums,10,14,start_x,start_y + BOX_HEIGHT,margin_x,margin_y,1,0);

  // int rpm = Integer.parseInt(nums[0]);
  // float speed = rpm * 0.032;
  // String speed_value = String.format("%.2f", speed);
  // String[] temp = {speed_value};
  // drawValues(temp, 0, 0,start_x+BOX_WIDTH*4,start_y+BOX_HEIGHT,margin_x, margin_y,1,0);
}

//Draw the boxes containing the BMS Values
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
  //If the event is a checkbox being clicked
  if(theEvent.isFrom(checkbox)){
      print("got an event from "+checkbox.getName()+"\t\n");
      println(checkbox.getArrayValue());
  }

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