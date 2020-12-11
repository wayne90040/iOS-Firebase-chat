# Firebase-chat-ios
### Firebase Practice

<details>
  <summary> Introduction </summary>
  
   - ### Firebase Chat App
   
   - Language
      - Swift
      
   - User Interface
      - Storyboard
   
   - Reference
      - Youtube: https://www.youtube.com/watch?v=BZEluKixqDA&list=PL5PR3UyfTWvdlk-Qi-dPtJmjTj-2YIMMf&index=2
   
</details>


## Add Firebase to your iOS project

#### Sign Up: 

```swift
Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
    guard result != nil, error == nil else{
        print("---Creating User Error---")
        return
    }
}
```

#### Sign In: 

```swift
Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
    guard result != nil, error == nil else {
        print("Fail to login with email: \(email)")
        return
    }
}
```
#### Reference: 
  https://firebase.google.com/docs/ios/setup?hl=en
  




      
    
    
