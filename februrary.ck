//------------------------------------------------------------------------------
// name: february.ck
// desc: A blend poem of Robert Frost's "Stopping by Woods on a Snowy Evening" 
//       and "A Prayer in Spring," transitioning from winter to spring. This poem
//       uses glove-wiki-gigaword-50.txt for the pre-trained word vector model.  
// sorting: part of chAI (ChucK for AI)
//
// "February: Winter to Spring"
// -- a midpoint between seasons
//
// author: Andrew T. Lee
// date: January 2023
//------------------------------------------------------------------------------


// INITIALIZATIONS:

// Word2Vec Model
Word2Vec model;
me.dir() + "glove-wiki-gigaword-50.txt" => string filepath;
if( !model.load( filepath ) )
{
    <<< "cannot load model:", filepath >>>;
    me.exit();
}

// CONSTANTS
model.dim() => int VECTSIZE;
16 => int NLINES;
4 => int NSTANZAS;
400::ms => dur T;
false => int shouldScaleTimeToWordLength;

// SOUND
ModalBar bar => NRev reverb => dac;
// reverb wet/dry mix
.1 => reverb.mix;
// which preset
7 => bar.preset;






// FUNCTIONS:

// Function: convert_file_to poem: Takes in a file path for a poem and 
// converts it into a nested array of strings. 
fun string[][] convert_file_to_poem(string filepath) {
    FileIO fio;
    StringTokenizer tokenizer;
    string line;
    string word;
    string poem[NLINES][0];
    
    fio.open( filepath, fio.READ );
    // read each line of the poem
    for (0 => int i; i < NLINES; i++) {
        fio.readLine() => line;
        tokenizer.set( line );

        // read the words in the current line
        0 => int j;
        while( tokenizer.more() ) {
            tokenizer.next() => word;
            j + 1 => poem[i].size;
            word => poem[i][j];
            j++;
        }
    }
    return poem;
}


// Function: print: Takes in a poem, in array form, and prints 
// it out in the console. Use this for test checking.
fun void print(string poem[][]) {
    for (0 => int i; i < NLINES; i++) {
        for (0 => int j; j < poem[i].size(); j++) {
            chout <= poem[i][j] <= " ";
        }
        chout <= IO.newline(); chout.flush();
        if ((i + 1) % NSTANZAS == 0) {
            chout <= IO.newline(); chout.flush();
        }
    }
}


// Function: blend_poems: Takes in two poems, and transitions from one
// to the other linearly using word vector arithmetic. 
fun string[][] blend_poems(string poemA[][], string poemB[][]) {
    string blendPoem[NLINES][0];
    1.0 => float percent_a;
    0.0 => float percent_b;
    (percent_a - percent_b) / (NLINES - 1) => float factor;
    
    // First and last line of blend poem should be same as the originals'
    poemA[0] @=> blendPoem[0];
    poemB[NLINES - 1] @=> blendPoem[NLINES - 1];
    
    // Generate each line for the resulting poem
    for (1 => int i; i < NLINES - 1; i++) {
        factor +=> percent_b;
        1 - percent_b => percent_a;
        poemA[i] @=> string lineA[];
        poemB[i] @=> string lineB[];
        string newLine[0];
        
        // determine the word length of this line
        if ( lineA.size() <= lineB.size() ) {
            lineA.size() => newLine.size;
        } else {
            lineB.size() => newLine.size;
        }
        
        // Use language model to generate the blended line. For each word,
        // calculate the vector weighted average, and get the closest word
        // with that new vector coordinate.
        for ( 0 => int j; j < newLine.size(); j++ ) {
            lineA[j] => string wordA;
            float vectorA[VECTSIZE];
            model.getVector(wordA, vectorA);
            
            lineB[j] => string wordB;
            float vectorB[VECTSIZE];
            model.getVector(wordB, vectorB);
            
            float vectorNew[VECTSIZE];
            
            for( 0 => int v; v < VECTSIZE; v++ ) {
                vectorA[v]*percent_a + vectorB[v]*percent_b => vectorNew[v];
            }
            
            string newWord[5];
            model.getSimilar(vectorNew, newWord.size(), newWord);
            newWord[ Math.random2(0, newWord.size()-1) ] => newLine[j];
        }
        // Add this new line to the resulting blend poem
        newLine @=> blendPoem[i];
    }
    return blendPoem;
}
 

// Function: sonify: Takes in a poem, in array form, and turns it 
// into a song.
fun void sonify( string poem[][]) {
    0.5 => float velocity;
    [54, 58, 61, 65, 66] @=> int pitches[];
    for ( 0 => int i; i < NLINES; i++ ) {
        0.10 +=> velocity;

        for ( 0 => int j; j < poem[i].size(); j++ ) {
            pitches[Math.random2(0, pitches.size()-1)] => int pitch;
            play(poem[i][j], pitch, velocity);
            wait( T );
        }
        // add another note to lines with an even number of words to sound
        // metrically comfortable
        if (poem[i].size() % 2 == 0) {
            pitches[Math.random2(0, pitches.size()-1)] => int pitch;
            pitch => Std.mtof => bar.freq;
            velocity => bar.noteOn;
        }
        endl( T );
        wait( T );
        if ((i + 1) % NSTANZAS == 0) {
            endl( T );
            wait( T );
            0.5 => velocity;
            // shift up the scale
            for (0 => int p; p < pitches.size()-1; p++) 4 +=> pitches[p];
        }
    }
}


// Helper function for Sonify: play
fun void play( string word, int pitch, float velocity ) {
    chout <= word <= " "; chout.flush();
    pitch => Std.mtof => bar.freq;
    velocity => bar.noteOn;
}

// Helper function for Sonify: wait
fun void wait( dur T ) {
    T => now;
}

// Helper function for Sonify: endl
fun void endl( dur T ) {
    chout <= IO.newline(); chout.flush();
    T => now;
}






// MAIN:

// Get the two Robert Frost Poems
me.sourceDir() + "stopping-by-woods.txt" => string winterFile;
if( me.args() > 0 ) me.arg(0) => winterFile;
string winterPoem[0][0];
convert_file_to_poem(winterFile) @=> winterPoem;

me.sourceDir() + "prayer-in-spring.txt" => string springFile;
if( me.args() > 0 ) me.arg(0) => springFile;
string springPoem[0][0];
convert_file_to_poem(springFile) @=> springPoem;

// Optional: test check if poems were correctly converted into the array form
// print(winterPoem);
// print(springPoem);

// Blend the two poems together
string blendPoem[0][0];
blend_poems(winterPoem, springPoem) @=> blendPoem;
// Optional: test check if the blended poem is correct, or looks about right
// print(blendPoem);

// Title
chout <= IO.newline(); chout.flush();
chout <= "Februrary: Winter to Spring" <= IO.newline(); chout.flush();
chout <= IO.newline(); chout.flush();
wait( T );

// Sonify the blended poem
sonify(blendPoem);
