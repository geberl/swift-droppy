//: Playground - noun: a place where people can play

import Cocoa
import SwiftyJSON

var str = "Hello, playground"

let json = JSON(data: dataFromNetworking)
if let userName = json[0]["user"]["name"].string {
    //Now you got your value
}