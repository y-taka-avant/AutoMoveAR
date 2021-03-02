//
//  Extensions.swift
//  AutoMoveAR
//  Extensions from Creating a Game with SceneUnderstanding(Apple Sample)
//
//  Copyright © 2020 Apple Inc.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import ARKit

extension float4x4 {
    public init(_ position: SIMD3<Float>, normal: SIMD3<Float>) {
        // build a transform from the position and normal (up vector, perpendicular to surface)
        let absX = abs(normal.x)
        let absY = abs(normal.y)
        let abzZ = abs(normal.z)
        let yAxis = normalize(normal)
        // find a vector sufficiently different from yAxis
        var notYAxis = yAxis
        if absX <= absY, absX <= abzZ {
            // y of yAxis is smallest component
            notYAxis.x = 1
        } else if absY <= absX, absY <= abzZ {
            // y of yAxis is smallest component
            notYAxis.y = 1
        } else if abzZ <= absX, abzZ <= absY {
            // z of yAxis is smallest component
            notYAxis.z = 1
        } else {
            fatalError("couldn't find perpendicular axis")
        }
        let xAxis = normalize(cross(notYAxis, yAxis))
        let zAxis = cross(xAxis, yAxis)

        self = float4x4(SIMD4<Float>(xAxis, w: 0.0),
                        SIMD4<Float>(yAxis, w: 0.0),
                        SIMD4<Float>(zAxis, w: 0.0),
                        SIMD4<Float>(position, w: 1.0))
    }
}

extension SIMD4 where Scalar == Float {
    init(_ xyz: SIMD3<Float>, w: Float) {
        self.init(xyz.x, xyz.y, xyz.z, w)
    }

    var xyz: SIMD3<Float> {
        get { return SIMD3<Float>(x: x, y: y, z: z) }
        set {
            x = newValue.x
            y = newValue.y
            z = newValue.z
        }
    }
}
