import java.util.ArrayList;
import java.util.List;
import java.util.TreeSet;
import java.util.Iterator;
import java.util.HashSet;

class BlobDetection {
  PImage findConnectedComponents(PImage input, boolean onlyBiggest) {
    // First pass: label the pixels and store labels' equivalences

    int [] labels= new int [input.width*input.height];
    List<TreeSet<Integer>> labelsEquivalences= new ArrayList<TreeSet<Integer>>();
    int currentLabel=1;

    for (int i = 0; i < input.width; ++i) {
      for (int j = 0; j < input.height; ++j) {
        labels[j*input.width +i] = 0;
      }
    }

    for (int i = 0; i < input.width; ++i) {
      for (int j = 0; j < input.height; ++j) {
        
        int index = j*input.width + i;  
        if (input.pixels[index] == color(255, 255, 255)) {
          TreeSet<Integer> neighbours = new TreeSet<Integer>();
          int localMinimum = Integer.MAX_VALUE;
          
          int k;
          int l = j - 1;
          
          for (k = i - 1; k <= i+1; ++k){
            if (!(k == i && l == j) && k >= 0 && k < input.width && l >= 0 && l < input.height) {
              if (labels[l*input.width + k] != 0) {
                if (input.pixels[l*input.width +k] == color(255, 255, 255)) neighbours.add(labels[l*input.width + k]);
                localMinimum = min(labels[l*input.width + k], localMinimum);
              }
            }
          }
         
          k = i - 1;
          l = j;
          if (!(k == i && l == j) && k >= 0 && k < input.width && l >= 0 && l < input.height) {
            if (labels[l*input.width + k] != 0) {
              if (input.pixels[l*input.width +k] == color(255, 255, 255)) neighbours.add(labels[l*input.width + k]);
              localMinimum = min(labels[l*input.width + k], localMinimum);
            }
          }

          if (neighbours.size() == 1) {
           labels[index] = neighbours.first();
          }
          else if (localMinimum == Integer.MAX_VALUE) {
            labels[index] = currentLabel;
            TreeSet newa = new TreeSet<Integer>();
            newa.add(currentLabel);
            labelsEquivalences.add(newa);
            currentLabel++;
          } else {
            labels[index] = localMinimum;
            TreeSet<Integer> goThrough = new TreeSet(neighbours);
            for (Integer a : goThrough) neighbours.addAll(labelsEquivalences.get(a - 1));              
            for (Integer a : neighbours) labelsEquivalences.get(a-1).addAll(neighbours);            
          }
        }
      }
    }

    int [] newLabels= new int [input.width*input.height];

    int[] nbIterations = new int[currentLabel];
    int max = 0;
    int maxLabel = 0;

    for (int i = 0; i < input.width; ++i) {
      for (int j = 0; j < input.height; ++j) {
        int index = j*input.width + i;
        if (input.pixels[index] == color(255, 255, 255)) {
          newLabels[index] = labelsEquivalences.get(labels[index]-1).first();
          nbIterations[newLabels[index] - 1] = nbIterations[newLabels[index] - 1] +1;
          if (nbIterations[newLabels[index]-1] > max) {
            max = nbIterations[newLabels[index] -1];
            maxLabel = newLabels[index];
          }
        }
      }
    }

    PImage result = createImage(input.width, input.height, RGB);
    result.loadPixels();
    if (onlyBiggest == false) {
      for (int i = 0; i < input.width; ++i) {
        for (int j = 0; j < input.height; ++j) {
          int index = j*input.width + i;
          if (input.pixels[index] == color(255, 255, 255)) {
            int coloring = newLabels[index]*5;
            result.pixels[index] = color(coloring*5, coloring*2, coloring);
          } else {
            result.pixels[index] = color(0, 0, 0);
          }
        }
      }
    } else {
      for (int i = 0; i < input.width; ++i) {
        for (int j = 0; j < input.height; ++j) {
          int index = j*input.width+i;
          if (input.pixels[j*input.width +i] == color(255, 255, 255)) {
            int value = newLabels[index];
            if (value == maxLabel) {
              result.pixels[index] = color(0, 255, 0);
            } else result.pixels[index] = color(0, 0, 0);
          } else result.pixels[index] = color(0, 0, 0);
        }
      }
    }

    return result;
  }
}