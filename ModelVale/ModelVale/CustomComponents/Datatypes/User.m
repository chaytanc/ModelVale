//
//  User.m
//  ModelVale
//
//  Created by Chaytan Inman on 7/27/22.
//

#import "User.h"
@import FirebaseCore;

@implementation User

/*

 func getUserInfo(fieldType: String, completion: @escaping(_ userData: [String : String], _ error: Error?) -> Void) {
     let uid = getUID()
     // Get the users' stoveInfo data
     db.collection("users").document(uid).getDocument(completion: { (document, error) in
         if error != nil {
             print("--- Could not query database for given fieldType: \n \(error)")
             let emptyData = [String:String]()
             completion(emptyData, error)
         }
         else {
             let data = document?.data() as! [String: [String: String]]
             let specificData = data[fieldType]
             completion(specificData!, error)
         }
     })
 }
 */


@end
