//-----------------------------------------------------------------------------
// Copyright (c) 2012 GarageGames, LLC
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.
//-----------------------------------------------------------------------------

// An implementation of "Practical Morphological Anti-Aliasing" from 
// GPU Pro 2 by Jorge Jimenez, Belen Masia, Jose I. Echevarria, 
// Fernando Navarro, and Diego Gutierrez.
//
// http://www.iryoku.com/mlaa/

#include "../../../gl/hlslCompat.glsl"

in vec2 texcoord;

uniform sampler2D edgesMap;
uniform sampler2D edgesMapL;
uniform sampler2D areaMap;

out vec4 OUT_col;

#include "./functions.glsl"


void main()
{
   vec4 areas = vec4(0.0);

   vec2 e = texture(edgesMap, texcoord).rg;	

   //[branch]
   if (bool(e.g)) // Edge at north
   { 
      // Search distances to the left and to the right:
      vec2 d = vec2(SearchXLeft(texcoord), SearchXRight(texcoord));

      // Now fetch the crossing edges. Instead of sampling between edgels, we
      // sample at -0.25, to be able to discern what value has each edgel:
      vec4 coords = mad(vec4(d.x, -0.25, d.y + 1.0, -0.25),
                                 PIXEL_SIZE.xyxy, texcoord.xyxy);
      float e1 = tex2Dlevel0(edgesMapL, coords.xy).r;
      float e2 = tex2Dlevel0(edgesMapL, coords.zw).r;

      // Ok, we know how this pattern looks like, now it is time for getting
      // the actual area:
      areas.rg = Area(abs(d), e1, e2);
   }

   //[branch]
   if (bool(e.r)) // Edge at west
   {
      // Search distances to the top and to the bottom:
      vec2 d = vec2(SearchYUp(texcoord), SearchYDown(texcoord));

      // Now fetch the crossing edges (yet again):
      vec4 coords = mad(vec4(-0.25, d.x, -0.25, d.y + 1.0),
                                 PIXEL_SIZE.xyxy, texcoord.xyxy);
      float e1 = tex2Dlevel0(edgesMapL, coords.xy).g;
      float e2 = tex2Dlevel0(edgesMapL, coords.zw).g;

      // Get the area for this direction:
      areas.ba = Area(abs(d), e1, e2);
   }

   OUT_col = areas;
}