/*
  Copyright (C) 2016 Rory Walsh

  Cabbage is free software; you can redistribute it
  and/or modify it under the terms of the GNU General Public
  License as published by the Free Software Foundation; either
  version 2.1 of the License, or (at your option) any later version.

  Cabbage is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Lesser General Public License for more details.

  You should have received a copy of the GNU General Public
  License along with Csound; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
  02111-1307 USA
*/

#include "CabbageSoundfiler.h"
#include "../Audio/Plugins/CabbagePluginEditor.h"

CabbageSoundfiler::CabbageSoundfiler (ValueTree wData, CabbagePluginEditor* _owner, int sr)
    : soundfiler (sr, Colour::fromString (CabbageWidgetData::getStringProp (wData, CabbageIdentifierIds::colour)),
                  Colour::fromString (CabbageWidgetData::getStringProp (wData, CabbageIdentifierIds::tablebackgroundcolour))),
    file (CabbageWidgetData::getStringProp (wData, CabbageIdentifierIds::file)),
    zoom (CabbageWidgetData::getNumProp (wData, CabbageIdentifierIds::zoom)),
    scrubberPos (CabbageWidgetData::getNumProp (wData, CabbageIdentifierIds::scrubberposition)),
    owner (_owner),
    widgetData (wData),
    CabbageWidgetBase(_owner)
{
    addAndMakeVisible (soundfiler);
    setName (CabbageWidgetData::getStringProp (wData, CabbageIdentifierIds::name));
    widgetData.addListener (this);              //add listener to valueTree so it gets notified when a widget's property changes
    initialiseCommonAttributes (this, wData);   //initialise common attributes such as bounds, name, rotation, etc..


    sampleRate = 44100;
    soundfiler.setZoomFactor (CabbageWidgetData::getNumProp (wData, CabbageIdentifierIds::zoom));


    //if no channels are set remove the selectable range feature

    if (CabbageWidgetData::getNumProp (wData, CabbageIdentifierIds::scrubberposition) < 0)
        soundfiler.shouldShowScrubber (false);

    if (CabbageWidgetData::getProperty (wData, CabbageIdentifierIds::channel).size() == 0)
        soundfiler.setIsRangeSelectable (false);

    soundfiler.setFile (File::getCurrentWorkingDirectory().getChildFile(file));
    soundfiler.addChangeListener (this);
    
    var tables = CabbageWidgetData::getProperty (wData, CabbageIdentifierIds::tablenumber);
    
    for (int y = 0; y < tables.size(); y++)
    {
        int tableNumber = tables[y];
        tableValues.clear();
        tableValues = owner->getTableFloats (tableNumber);
        AudioBuffer<float> sampleBuffer;
        sampleBuffer.setSize(1, tableValues.size());
        //has to be a quicker way of doing this...
        for ( int i = 0 ; i < tableValues.size() ; i++){
            sampleBuffer.setSample(0, i, tableValues[i]);
        }

        setWaveform(sampleBuffer, 1);
    }
    
    if (CabbageWidgetData::getNumProp (wData, CabbageIdentifierIds::startpos) > -1 && CabbageWidgetData::getNumProp (wData, CabbageIdentifierIds::endpos) > 0)
    {
        Range<double> newRange;
        
        newRange.setStart(CabbageWidgetData::getNumProp (wData, CabbageIdentifierIds::startpos)/sampleRate);
        newRange.setEnd(CabbageWidgetData::getNumProp (wData, CabbageIdentifierIds::endpos)/sampleRate);
        soundfiler.setRange (newRange);
    }
    
    const int scrollbars = CabbageWidgetData::getNumProp (wData, CabbageIdentifierIds::scrollbars);
    if(scrollbars == 0)
        soundfiler.showScrollbars(false);
    
    soundfiler.shouldShowScrubber(CabbageWidgetData::getNumProp (wData, CabbageIdentifierIds::showscrubber) == 1 ? true : false );
}

void CabbageSoundfiler::changeListenerCallback (ChangeBroadcaster* source)
{
    //no need to check source, it has to be a soundfiler object
    const float position = getScrubberPosition();
    const float length = getLoopLength();

    owner->sendChannelDataToCsound (getChannelArray()[0], position);

    if (getChannelArray().size() > 1)
        owner->sendChannelDataToCsound (getChannelArray()[1], length);
}

void CabbageSoundfiler::resized()
{
    soundfiler.setBounds (0, 0, getWidth(), getHeight());
}

void CabbageSoundfiler::setFile (String newFile)
{
    soundfiler.setFile (File::getCurrentWorkingDirectory().getChildFile (newFile));
}

void CabbageSoundfiler::setWaveform (AudioSampleBuffer buffer, int channels)
{
    soundfiler.setWaveform (buffer, channels);
}

int CabbageSoundfiler::getScrubberPosition()
{
    return soundfiler.getCurrentPlayPosInSamples();
}

int CabbageSoundfiler::getLoopLength()
{
    return soundfiler.getLoopLengthInSamples();
}

void CabbageSoundfiler::valueTreePropertyChanged (ValueTree& valueTree, const Identifier& prop)
{
    DBG(CabbageWidgetData::getStringProp (valueTree, CabbageIdentifierIds::identchannel));
    
    if (file != CabbageWidgetData::getStringProp (valueTree, CabbageIdentifierIds::file))
    {
        file = CabbageWidgetData::getStringProp (valueTree, CabbageIdentifierIds::file);
        const String fullPath = File (getCsdFile()).getParentDirectory().getChildFile (file).getFullPathName();
        setFile (fullPath);
    }

    if (zoom != CabbageWidgetData::getNumProp (valueTree, CabbageIdentifierIds::zoom))
    {
        zoom = CabbageWidgetData::getNumProp (valueTree, CabbageIdentifierIds::zoom);
        soundfiler.setZoomFactor (zoom);
    }

    if(prop == CabbageIdentifierIds::startpos || prop == CabbageIdentifierIds::endpos)
    {
        if (CabbageWidgetData::getNumProp (valueTree, CabbageIdentifierIds::startpos) > -1 && CabbageWidgetData::getNumProp (valueTree, CabbageIdentifierIds::endpos) > 0)
        {
            Range<double> newRange;
            newRange.setStart(CabbageWidgetData::getNumProp (valueTree, CabbageIdentifierIds::startpos)/sampleRate);
            newRange.setEnd(CabbageWidgetData::getNumProp (valueTree, CabbageIdentifierIds::endpos)/sampleRate);
            soundfiler.setRange (newRange);
        }
    }
    
    soundfiler.setScrubberPos (CabbageWidgetData::getNumProp (valueTree, CabbageIdentifierIds::scrubberposition));
    soundfiler.setWaveformColour (CabbageWidgetData::getStringProp (valueTree, CabbageIdentifierIds::colour));
    soundfiler.setBackgroundColour (CabbageWidgetData::getStringProp (valueTree, CabbageIdentifierIds::tablebackgroundcolour));
    handleCommonUpdates (this, valueTree, false, prop);      //handle comon updates such as bounds, alpha, rotation, visible, etc
    soundfiler.repaint();
    repaint();

}
