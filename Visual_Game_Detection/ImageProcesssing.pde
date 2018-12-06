import java.util.Collections;
import gab.opencv.*;
import processing.video.*;

class ImageProcessing extends PApplet {
  PImage img;

  QuadGraph quad;
  BlobDetection detector;

  OpenCV opencv;
  TwoDThreeD twoDThreeD;

  PGraphics imgWithLines;
  PVector rot = new PVector(0, 0, 0);

  int imgWidth = 640;
  int imgHeight = 480;
  
  boolean pause = true;

  void settings() {
    size(640, 480, P2D);
  }

  void setup() {
    opencv = new OpenCV(this, 100, 100);

    quad = new QuadGraph();
    detector = new BlobDetection();

    twoDThreeD = new TwoDThreeD(imgWidth, imgHeight, 20);
    imgWithLines = createGraphics(imgWidth, imgHeight);
  }

  void draw() {
    if (!stop) {
      if(pause){
        cam.loop();
      }
      pause = false;
      
      background(0);
      if (cam.available() == true) {
        cam.read();
      }
      img = cam.get();
      PImage threshold = thresholdHSB(img, 50, 130, 20, 255, 0, 255);

      PImage blob = detector.findConnectedComponents(threshold, true);

      PImage blurred = convolute(blob);

      PImage edge = scharr(blurred);

      PImage brightness = threshold(edge, 100);

      ArrayList<PVector> lines = hough(brightness, 4);

      List<PVector> bestQuads = quad.findBestQuad(lines, img.width, img.height, img.width*img.height, 300*200, false);

      for (int i = 0; i < bestQuads.size(); ++i) {
        bestQuads.get(i).z = 1;
      }

      if (bestQuads.size() == 4) {
        rot = twoDThreeD.get3DRotations(bestQuads);
        rot.z = 0;
        
        //We are using the same rotation calculation as in the Competition because we thought it was the most intuitive one.
        if (rot.x > 0) {
          rot.x -= PI;
        } else if (rot.x < 0) {
          rot.x += PI;
        }
      }

      drawImg(lines, bestQuads);
      image(imgWithLines, 0, 0);
    }else{
      cam.pause();
      pause = true;
    }
  }

  void drawImg(ArrayList<PVector> lines, List<PVector> quads) {
    imgWithLines.beginDraw();
    imgWithLines.image(img, 0, 0);
    drawLines(lines, imgWithLines);
    drawQuads(quads, imgWithLines);
    imgWithLines.endDraw();
  }

  void drawQuads(List<PVector> quads, PGraphics graphics) {
    graphics.stroke(0);
    for (int i = 0; i < quads.size(); ++i) {
      graphics.fill(random(255), random(255), random(255), 100);
      PVector pos = quads.get(i);
      graphics.ellipse(pos.x, pos.y, 30, 30);
    }
  }

  PVector getRotations() {
    return new PVector(rot.x, rot.y);
  }

  void drawLines(ArrayList<PVector> lines, PGraphics graphics) {
    for (int idx = 0; idx < lines.size(); idx++) {
      PVector line=lines.get(idx);
      float r = line.x;
      float phi = line.y;
      // Cartesian equation of a line: y = ax + b
      // in polar, y = (-cos(phi)/sin(phi))x + (r/sin(phi))
      // => y = 0 : x = r / cos(phi)
      // => x = 0 : y = r / sin(phi)
      // compute the intersection of this line with the 4 borders of
      // the image
      int x0 = 0;
      int y0 = (int) (r / sin(phi));
      int x1 = (int) (r / cos(phi));
      int y1 = 0;
      int x2 = img.width;
      int y2 = (int) (-cos(phi) / sin(phi) * x2 + r / sin(phi));
      int y3 = img.width;
      int x3 = (int) (-(y3 - r / sin(phi)) * (sin(phi) / cos(phi)));
      // Finally, plot the lines
      graphics.stroke(204, 102, 0);
      if (y0 > 0) {
        if (x1 > 0)
          graphics.line(x0, y0, x1, y1);
        else if (y2 > 0)
          graphics.line(x0, y0, x2, y2);
        else
          graphics.line(x0, y0, x3, y3);
      } else {
        if (x1 > 0) {
          if (y2 > 0)
            graphics.line(x1, y1, x2, y2);
          else
            graphics.line(x1, y1, x3, y3);
        } else
          graphics.line(x2, y2, x3, y3);
      }
    }
  }

  ArrayList<PVector> hough(PImage edgeImg, int nLines) {
    float discretizationStepsPhi = 0.06f; 
    float discretizationStepsR = 2.5f; 
    int minVotes = 175; 

    ArrayList<Integer> bestCandidates = new ArrayList<Integer>();

    // dimensions of the accumulator
    int phiDim = (int) (Math.PI / discretizationStepsPhi +1);
    //The max radius is the image diagonal, but it can be also negative
    int rDim = (int) ((sqrt(edgeImg.width*edgeImg.width +
      edgeImg.height*edgeImg.height) * 2) / discretizationStepsR +1);

    // our accumulator
    int[] accumulator = new int[phiDim * rDim];

    for (int y = 0; y < edgeImg.height; y++) {
      for (int x = 0; x < edgeImg.width; x++) {
        // Are we on an edge?
        if (brightness(edgeImg.pixels[y * edgeImg.width + x]) != 0) {
          for (int index = 0; index < (int)(PI/discretizationStepsPhi); ++index) {
            float phi2 = index* discretizationStepsPhi;
            float r = x*cos(phi2)+y*sin(phi2); 
            r= Math.round( r/discretizationStepsR);
            r+=rDim/2;

            int indexAcc = (int)(index* rDim+r);
            accumulator[indexAcc]+=1;
          }
        }
      }
    }

    ArrayList<PVector> lines=new ArrayList<PVector>();
    //________________________________________
    // Optimization to find the best maximum
    int regionSize = 10;

    for (int i=0; i<accumulator.length; ++i) {
      int r = i%rDim;
      int phi = i /rDim;
      Boolean b = true;
      for (int w = r-regionSize; w<r+regionSize; ++w) {
        for (int h = phi-regionSize; h<phi+regionSize; ++h) {
          if (w>= 0 && w<rDim && h>=0 && h < phiDim) {
            if (accumulator[i]<accumulator[h*rDim+w]) {
              b=false;
            }
          }
        }
      }
      if (b) {
        bestCandidates.add(i);
      }
    }

    Collections.sort(bestCandidates, new HoughComparator(accumulator));

    for (int idx = 0; idx < nLines; idx++) {
      int index = bestCandidates.get(idx);
      if (accumulator[index] > minVotes) {
        // first, compute back the (r, phi) polar coordinates:
        int accPhi = (int) (index / (rDim));
        int accR = index - (accPhi) * (rDim);
        float r = (accR - (rDim) * 0.5f) * discretizationStepsR;
        float phi = accPhi * discretizationStepsPhi;
        lines.add(new PVector(r, phi));
      }
    }


    return lines;
  }

  PImage thresholdHSB(PImage img, int minH, int maxH, int minS, int maxS, int minB, int maxB) {
    PImage result = createImage(img.width, img.height, RGB);
    img.loadPixels();
    result.loadPixels();
    for (int i = 0; i < img.width * img.height; i++) {
      if (hue(img.pixels[i]) >= minH && hue(img.pixels[i]) <= maxH && saturation(img.pixels[i]) >= minS && saturation(img.pixels[i]) <= maxS && brightness(img.pixels[i]) >= minB && brightness(img.pixels[i]) <= maxB) {
        result.pixels[i] = color(255, 255, 255);
      } else {
        result.pixels[i] = color(0, 0, 0);
      }
    }
    result.updatePixels();
    return result;
  }

  PImage convolute(PImage img) {
    float[][] kernel = { { 9, 12, 9 }, 
      { 12, 15, 12 }, 
      { 9, 12, 9 }};
    float normFactor = 99.f;
    // create a greyscale image (type: ALPHA) for output
    PImage result = createImage(img.width, img.height, ALPHA);

    result.loadPixels();
    img.loadPixels();

    for (int x = 1; x < img.width - 1; ++x) {
      for (int y = 1; y < img.height - 1; ++y) {
        float value = 0;
        for (int i = 0; i < kernel.length; ++i) {
          int indexX = x - kernel.length/2 + i;
          for (int j = 0; j < kernel.length; ++j) {
            int indexY = y - kernel.length/2 + j;
            value += brightness(img.pixels[indexX + indexY * img.width]) * kernel[i][j];
          }
        }
        value /= normFactor;
        result.pixels[x + y * img.width] = color(value, value, value);
      }
    }
    result.updatePixels();
    return result;
  }

  PImage scharr(PImage img) {
    float[][] vKernel = {
      { 3, 0, -3 }, 
      { 10, 0, -10 }, 
      { 3, 0, -3 } };

    float[][] hKernel = {
      { 3, 10, 3 }, 
      { 0, 0, 0 }, 
      { -3, -10, -3 } };

    PImage result = createImage(img.width, img.height, ALPHA);

    // clear the image
    for (int i = 0; i < img.width * img.height; i++) {
      result.pixels[i] = color(0);
    }
    float max=0;
    float[] buffer = new float[img.width * img.height];

    for (int x = 1; x < img.width - 1; ++x) {
      for (int y = 1; y < img.height - 1; ++y) {
        float sum_h = 0;
        float sum_v = 0;
        for (int i = 0; i < vKernel.length; ++i) {
          int indexX = x - vKernel.length/2 + i;
          for (int j = 0; j < vKernel.length; ++j) {
            int indexY = y - vKernel.length/2 + j;
            sum_h += brightness(img.pixels[indexX + indexY * img.width]) * hKernel[i][j];
            sum_v += brightness(img.pixels[indexX + indexY * img.width]) * vKernel[i][j];
          }
        }
        float sum = sqrt(pow(sum_h, 2) + pow(sum_v, 2));
        max = max(sum, max);
        buffer[x + y * img.width] = sum;
      }
    }

    for (int y = 2; y < img.height - 2; y++) { // Skip top and bottom edges
      for (int x = 2; x < img.width - 2; x++) { // Skip left and right
        int val=(int) ((buffer[y * img.width + x] / max)*255);
        result.pixels[y * img.width + x]=color(val);
      }
    }
    return result;
  }

  PImage threshold(PImage img, int threshold) {
    // create a new, initially transparent, 'result' image
    PImage result = createImage(img.width, img.height, RGB);
    img.loadPixels();
    result.loadPixels();
    for (int i = 0; i < img.width * img.height; i++) {
      if (brightness(img.pixels[i]) >= threshold) {
        result.pixels[i] = color(255, 255, 255);
      } else {
        result.pixels[i] = color(0, 0, 0);
      }
    }
    result.updatePixels();
    return result;
  }
}
