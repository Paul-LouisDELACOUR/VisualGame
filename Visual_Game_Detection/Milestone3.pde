import processing.video.*;
Movie cam;

float cylinderBaseSize = 30;
float cylinderHeight = 40;
int cylinderResolution = 40;

PShape openCylinder = new PShape();
PShape bottom = new PShape();
PShape top = new PShape();

ArrayList<PVector> cylPos = new ArrayList();

float taillePlateau = 400;
float taillePlateauY = 20;
float rayonSphere = 25;

float deltaX = 0;
float deltaY = 0;

float rx = 0;
float rz = 0;

float speed = 1;

float topSpeed = 10;

float scaleCylinder = 1.258;

float angleBallX = 0;
float angleBallZ = 0;

float factorAngleBall = 1/rayonSphere;

Mover mover;

boolean stop = false;

PImage img;
PShape sphere;

PGraphics gameSurface;
PGraphics bottomSurface;
PGraphics topView;
PGraphics scoreboard;
PGraphics barChart;

int padding = 10;
int heightOfBottom = 150;
int widthOfScoreboard = 165;

float score = 100;
float lastScore = 0;

//If velocity is smaller or equal to this, don't update score
float tresholdScore = 0.7;

int sizeOfSquares = 5;
int scoreOfSquare = 10;
float sizeOfSquaresScaled = sizeOfSquares;
float minSizeOfSquares = 2;

//For optimisation, don't draw information that can't be displayed
int maxNumberOfSquares;
int maxNumberOfLines;

float scaleSquares = 1;

ArrayList<Integer> scores = new ArrayList();

PVector posMouseClicked = new PVector(0, 0);

HScrollbar hs;

int heightOfScrollbar = 10;

ImageProcessing imgproc;


void settings() {
  size(600, 600, P3D);
}

void setup() {
  cam = new Movie(this, "testvideo.avi");
  mover = new Mover();
  float angle;
  float[] x = new float[cylinderResolution + 1];
  float[] z = new float[cylinderResolution + 1];
  //get the x and z position on a circle for all the sides
  for (int i = 0; i < x.length; i++) {
    angle = (TWO_PI / cylinderResolution) * i;
    x[i] = sin(angle) * cylinderBaseSize;
    z[i] = cos(angle) * cylinderBaseSize;
  }
  openCylinder = createShape();
  openCylinder.beginShape(QUAD_STRIP);
  //draw the border of the cylinder
  for (int i = 0; i < x.length; i++) {
    openCylinder.vertex(x[i], 0, z[i]);
    openCylinder.vertex(x[i], cylinderHeight, z[i]);
  }
  openCylinder.endShape();

  bottom = createShape();
  bottom.beginShape(TRIANGLE_FAN);
  bottom.vertex(0, 0, 0);
  for (int i = 0; i < x.length; i++) {
    bottom.vertex(x[i], 0, z[i]);
  }
  bottom.endShape();

  top = createShape();
  top.beginShape(TRIANGLE_FAN);
  top.vertex(0, cylinderHeight, 0);
  for (int i = 0; i < x.length; i++) {
    top.vertex(x[i], cylinderHeight, z[i]);
  }
  top.endShape();

  img = loadImage("earth.jpg");
  sphere = createShape(SPHERE, rayonSphere);
  sphere.setStroke(false);
  sphere.setTexture(img);

  gameSurface = createGraphics(width, height - heightOfBottom, P3D);
  bottomSurface = createGraphics(width, heightOfBottom, P2D);
  topView = createGraphics(heightOfBottom - 2 * padding, heightOfBottom - 2 * padding, P2D);
  scoreboard = createGraphics(widthOfScoreboard, heightOfBottom - 2 * padding, P2D);
  barChart = createGraphics(width - 4 * padding - topView.width - scoreboard.width, heightOfBottom - 3 * padding - heightOfScrollbar, P3D);
  hs = new HScrollbar(3 * padding + topView.width + scoreboard.width, height - padding - heightOfScrollbar, barChart.width, heightOfScrollbar);

  //+1 just to make sure the rounding doesn't round down
  maxNumberOfLines = round(barChart.width/minSizeOfSquares) + 1;
  maxNumberOfSquares = round(barChart.height/minSizeOfSquares) + 1;

  imgproc = new ImageProcessing();
  String []args = {"Image processing window"};
  PApplet.runSketch(args, imgproc);
}

void draw() {    
  PVector currRot = new PVector(rx, rz);
  PVector newRot = imgproc.getRotations().copy();
  PVector dist = newRot.copy().sub(currRot.copy());

  //Move by 5° max as done in competition
  if (dist.copy().mag() > PI/36) {
    currRot = currRot.copy().add(dist.copy().normalize().mult(PI/36));
  } else {
    currRot = newRot.copy();
  }

  rx = currRot.x;
  rz = currRot.y;

  if (rx > PI/4) {
    rx = PI/4;
  }
  if (rx < -PI/2) {
    rx = -PI/2;
  }

  if (rz > PI/2) {
    rz = PI/2;
  }
  if (rz < -PI/2) {
    rz = -PI/2;
  }

  drawGame();
  image(gameSurface, 0, 0);

  drawBottom();
  image(bottomSurface, 0, height - heightOfBottom);

  drawTopView();
  image(topView, padding, height - (heightOfBottom - padding));

  drawScoreboard();
  image(scoreboard, 2 * padding + topView.width, height - (heightOfBottom - padding));

  drawBarChart();
  image(barChart, 3 * padding + topView.width + scoreboard.width, height - (heightOfBottom - padding));

  hs.update();
  hs.display();
}

void mouseWheel(MouseEvent event) {
  if (!stop) {
    float e = event.getCount();
    if (e < 0) {
      speed += 0.2;
      speed = min(speed, 5);
    }
    if (e > 0) {
      speed -= 0.2;
      speed = max(speed, 0.1);
    }
    println("Speed of rotation = " + speed);
  }
}

void keyPressed() {
  if (key == CODED) {
    if (keyCode == SHIFT) {
      stop = true;
    }
  }
}

void keyReleased() {
  if (key == CODED) {
    if (keyCode == SHIFT) {
      stop = false;
    }
  }
}

void mousePressed() {
  if (stop) {
    if (mouseButton == LEFT) {
      PVector vector = new PVector((mouseX - gameSurface.width/2) * scaleCylinder, -taillePlateauY/2 - cylinderHeight, (mouseY - gameSurface.height/2) * scaleCylinder);
      if (vector.x >= - taillePlateau/2 && vector.x <= taillePlateau/2 && vector.z >= -taillePlateau/2 && vector.z <= taillePlateau/2) {
        cylPos.add(vector);
      }
    }
  }
  posMouseClicked = new PVector(mouseX, mouseY);
}

void drawAllCylinders() {
  for (PVector vect : cylPos) {
    gameSurface.pushMatrix();
    gameSurface.translate(vect.x, vect.y, vect.z);
    gameSurface.shape(openCylinder);
    gameSurface.shape(top);
    gameSurface.shape(bottom);
    gameSurface.popMatrix();
  }
}

void drawGame() {
  gameSurface.beginDraw();

  if (!stop) {
    gameSurface.camera(gameSurface.width/2.0, 0, 500, gameSurface.width/2.0, gameSurface.height/2.0, 0, 0, 1, 0);
    //gameSurface.camera(gameSurface.width/2.0, gameSurface.height/2.0, 500, gameSurface.width/2.0, gameSurface.height/2.0, 0, 0, 1, 0);
  } else {
    gameSurface.camera(gameSurface.width/2.0, gameSurface.height/2.0, 500, gameSurface.width/2.0, gameSurface.height/2.0, 0, 0, 1, 0);
  }

  gameSurface.pushMatrix();

  gameSurface.background(200);

  gameSurface.translate(gameSurface.width/2, gameSurface.height/2, 0);

  gameSurface.pushMatrix();
  gameSurface.translate(0, gameSurface.height/2, -300);
  gameSurface.fill(0, 255, 0);
  //gameSurface.box(900, 10, 900);
  gameSurface.popMatrix();

  if (!stop) {
    gameSurface.rotateX(rx);
    gameSurface.rotateZ(rz);

    angleBallX += mover.velocity.z * factorAngleBall;
    angleBallZ += mover.velocity.x * factorAngleBall;

    mover.checkCylinderCollisions();
    mover.checkEdges();
    mover.update();
  }

  if (stop) {
    gameSurface.rotateX(-PI/2);
  }

  gameSurface.fill(255);
  gameSurface.box(taillePlateau, taillePlateauY, taillePlateau);


  drawAllCylinders();

  gameSurface.translate(mover.location.x, mover.location.y, mover.location.z);
  gameSurface.fill(255);
  gameSurface.rotateZ(angleBallZ);
  gameSurface.rotateX(-angleBallX);
  gameSurface.shape(sphere);

  gameSurface.popMatrix();
  gameSurface.endDraw();
}

void drawBottom() {
  bottomSurface.beginDraw();
  bottomSurface.background(150, 50, 200);
  bottomSurface.endDraw();
}

void drawAllCylinders2D(float scale) {
  for (PVector vect : cylPos) {
    topView.pushMatrix();
    topView.translate(vect.copy().x * scale, vect.copy().z * scale);
    topView.ellipse(0, 0, 2 * cylinderBaseSize * scale, 2 * cylinderBaseSize * scale);
    topView.popMatrix();
  }
}

void drawTopView() {
  topView.beginDraw();
  topView.background(0, 0, 255);
  topView.pushMatrix();

  topView.translate(topView.width/2, topView.height/2);

  float scale = topView.width/taillePlateau;

  topView.fill(0, 255, 0);
  drawAllCylinders2D(scale);

  topView.translate(mover.location.x * scale, mover.location.z * scale);

  topView.fill(255, 0, 0);
  topView.ellipse(0, 0, 2 * rayonSphere * scale, 2 * rayonSphere * scale);

  topView.popMatrix();
  topView.endDraw();
}

void drawScoreboard() {
  scoreboard.beginDraw();
  scoreboard.pushMatrix();

  scoreboard.background(0);
  scoreboard.textSize(18);
  scoreboard.fill(255, 255, 255);
  scoreboard.text("Total score:", 10, 20);
  scoreboard.text(score, 15, 40);

  scoreboard.text("Velocity:", 10, 60);
  scoreboard.text(mover.velocity.copy().mag(), 15, 80);

  scoreboard.text("Last score:", 10, 100);
  scoreboard.text(lastScore, 15, 120);

  scoreboard.popMatrix();
  scoreboard.endDraw();
}

void drawBarChart() {
  barChart.beginDraw();
  barChart.pushMatrix();

  barChart.background(0);

  //If the scrollbar is minimum, squares are minSizeOfSquares pixels wide
  scaleSquares = map(hs.getPos(), 0, 0.5, minSizeOfSquares/sizeOfSquares, 1);

  sizeOfSquaresScaled = scaleSquares * sizeOfSquares;

  //println("Size of scores = " + scores.size());
  //println("Max squares = " + maxNumberOfSquares);
  //println("Max lines = " + maxNumberOfLines);  

  int numberOfSquares = min(maxNumberOfSquares, (int)(score/scoreOfSquare));
  if (score <= 0) {
    numberOfSquares = 0;
  }
  scores.add(0, numberOfSquares);

  //Remove last elements until size has maximum useful size
  while (scores.size() > maxNumberOfLines) {
    scores.remove(scores.size() - 1);
  }

  barChart.translate(0, barChart.height);

  //float translateY = -sizeOfSquaresScaled;

  barChart.fill(255);
  barChart.stroke(0);

  barChart.pushMatrix();

  for (int i = 0; i < scores.size(); ++i) {
    numberOfSquares = scores.get(i);
    barChart.pushMatrix();
    barChart.translate(0, -numberOfSquares * sizeOfSquaresScaled);
    barChart.rect(0, 0, sizeOfSquaresScaled, numberOfSquares * sizeOfSquaresScaled);
    barChart.popMatrix();
    
    barChart.translate(sizeOfSquaresScaled, 0);
  }

  barChart.popMatrix();

  barChart.stroke(0);

  float i = sizeOfSquaresScaled;
  while (i < barChart.height) {
    barChart.line(0, -i, barChart.width, -i);
    i += sizeOfSquaresScaled;
  }

  barChart.popMatrix();
  barChart.endDraw();
}