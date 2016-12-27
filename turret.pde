import SimpleOpenNI.*;
import processing.serial.*;
SimpleOpenNI context;

int homeX = 100;
int homeY = 0;
int xpos = homeX;
int ypos = homeY;
float targetDistance;
int tolerance = 40;
float lastX = -1;
int lastMillis = 0;
float targetingDelay = 2000;
float percentLocked = 0;
Serial port; // The serial port we will be using
PVector com = new PVector();
PVector boundCenterOfMass = new PVector();

PShape square, center;

color[] userColor = new color[]{
  color(255,255,0),
  color(255,0,255),
  color(0,255,255)
};

void setup(){
  size(640, 480, P2D);

  context = new SimpleOpenNI(this);
  if(context.isInit() == false){
     println("Can't initialize SimpleOpenNI, camera not connected properly.");
     exit();
     return;
  }

  context.enableDepth();
  context.enableUser();
  context.setMirror(true);

  smooth();
  port = new Serial(this, Serial.list()[4], 19200);
  updateServo(homeX, homeY);
}

void updateServo(int x, int y)
{
  xpos = x;
  ypos = y;

  port.write(xpos + "x");
  port.write(ypos + "y");
}

void onNewUser(SimpleOpenNI curContext, int userId){
  println("onNewUser - userId: " + userId);
  //context.startTrackingSkeleton(userId);
}

void onLostUser(SimpleOpenNI curContext, int userId){
  println("onLostUser - userId: " + userId);
  //context.stopTrackingSkeleton(userId);
}

void resetBounds(float x, int userId) {
  int millis = millis();

  if (context.getCoM(userId, boundCenterOfMass)) {
    targetDistance = boundCenterOfMass.z;
  } else {
    targetDistance = 0; // no target distance use defaults
  }

  if (targetDistance == 0) {
    tolerance = 40;
  } else {
    // do the calculation
    tolerance = int(-40 * log(targetDistance) + 370); // I made up this function, it workss
    println("TOLERANCE:  " + tolerance);
  }
  lastMillis = millis;
  lastX = x;
  percentLocked = 0;
}

void checkMovement(float x, int userId) {
  int millis = millis();
  if (lastX == -1) {
    // first pass -> set defaults
    lastX = x;
    lastMillis = millis;
    return;
  }

  if (abs(lastX - x) > tolerance) {
    // target left bounds -> reset bounds
    resetBounds(x, userId);
    return;
  }

  float millisBeforeLock = (lastMillis + targetingDelay) - millis;
  percentLocked = 1.0 - millisBeforeLock / targetingDelay;

  if (lastMillis + 1.5*targetingDelay < millis) {
    // we lost the target -> resetBounds
    resetBounds(x, userId);
  } else if (lastMillis + targetingDelay < millis) { // 2 seconds have ellapsed
    println("FIREEEEEEE");
    fill(255, 0, 0, 125);
    rect(0, 0, 800, 800);
    resetBounds(x, userId); // target fired -> reset bounds prevents rapid fire
  }
}

int offsetX = 15;
int offsetY = 0;
void drawBoundingBox(int userId) {

  PVector bbMin = new PVector();
  PVector bbMax = new PVector();
  context.getBoundingBox(userId, bbMin, bbMax);

  if(bbMin.x < 2000 && bbMin.x >= 0) {
    float boxWidth = bbMax.x - bbMin.x;
    float boxHeight = bbMax.y - bbMin.y;
    square = createShape(RECT, bbMin.x - 20, bbMin.y - 20, boxWidth, boxHeight);
    float centerX = (bbMin.x - 20) + boxWidth/2;
    float centerY = (bbMin.y - 20) + boxHeight/2;
    center = createShape(RECT, centerX, centerY, 5, 5);

    center.setFill(false);
    center.setStroke(color(255));
    shape(center, 25, 25);
    square.setFill(false);
    square.setStroke(color(255));
    shape(square, 25, 25);

    checkMovement(centerX, userId);

    float X = 640 - centerX;
    float degreesPerPixel = .092;
    float startingViewAngle = 70 - offsetX;
    int servoX = int(X * degreesPerPixel + startingViewAngle);

    float Y = centerY;
    degreesPerPixel = .089 * 3; // 3x multiplier added to increase motion in y
    startingViewAngle = 113.5 + offsetY;
    int servoY = int(Y * degreesPerPixel + startingViewAngle);

    if(servoX < 90){
      servoX -= int((90 - servoX) / 4);
    }
    if (75 < servoX && servoX < 120) {
      servoX -= 5;
    }

    updateServo(180 - servoX, 180 - servoY);
  }
}


void draw(){
  context.update();
  image(context.userImage(),0,0);
  int[] userList = context.getUsers();

  if (userList.length == 0) {
    updateServo(homeX, homeY);
  }

  if(userList.length > 0) {
    for(int i = userList.length - 1; i >= 0; i--) {
      if(context.getCoM(userList[i], com)) {
        if (com.z > 0) {
          // shoot user
          drawBoundingBox(userList[i]);
          break;
        }
      } else {
        println("no com for userID: " + userList[i]);
      }
    }
  }

  stroke(26, 230, 230, 175);
  strokeWeight(5);
  line(lastX + 25 - tolerance, 40, lastX + 25 - tolerance, 440);
  line(lastX + 25 + tolerance, 40, lastX + 25 + tolerance, 440);
  fill(255, 0, 0, 155);
  stroke(0);
  strokeWeight(1);
  rect(0, 469, percentLocked * width,10);
}

void keyPressed() {
  if (key == 'h') {
    updateServo(homeX, homeY);
  }
}
