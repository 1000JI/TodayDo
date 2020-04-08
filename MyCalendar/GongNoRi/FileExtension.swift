//
//  FileExtension.swift
//  PhotoLog_4
//
//  Created by 김재경 on 13/04/2019.
//  Copyright © 2019 jack. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    
    //파일 디렉토리 경로 가져오기
    func getDirectoryPath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    //디렉토리에 이미지 파일을 저장
    func savePhotosToDocumentDirectory(image : UIImage, fileName : String){
        
        //1. 파일 시스템 불러오기
        let fileManager = FileManager.default
        do {
            
            //파일 시스템의 Document에 접근
            let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
            
            //ex desktop/강의/PhotoLog > document/40.jpg
            //ERROR : 폴더 생성
            let fileURL = documentDirectory.appendingPathComponent(fileName)
            
            //파일 압축
            if let imageData = image.jpegData(compressionQuality: 0.2) {
                try imageData.write(to: fileURL)
                
                print("SAVE SUCCEED")
                
            }
        } catch {
            print(error)
        }
        
    }
    
}
