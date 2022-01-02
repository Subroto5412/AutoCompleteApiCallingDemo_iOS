//
//  ViewController.swift
//  AutoCompleteApiCallingDemo
//
//  Created by masco bazar on 2/1/22.
//

import UIKit

class CellClass: UITableViewCell {
}

class ViewController: UIViewController {

    @IBOutlet weak var myTextField: UITextField!
    
    var searching = false
//    var allCountry = ["Afghanistan", "Armenia","Australia","Austria", "Bangladesh","Belize", "Belgium","China","Colombia","Dominica"]
    
    var dataSource = [ListUnitName]()
    var filteredDataSource = [ListUnitName]()
    
    let transparentView = UIView()
    let tableViewDropDown = UITableView()
    
    var selectedButton = UITextField()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.getUnitNameList()
        
        tableViewDropDown.delegate = self
        tableViewDropDown.dataSource = self
        tableViewDropDown.register(CellClass.self, forCellReuseIdentifier: "Cell")
        
        myTextField.addTarget(self, action: #selector(searchRecord), for: .editingChanged)
        
    }

    @objc func searchRecord(sender:UITextField ){
        self.filteredDataSource.removeAll()
        let searchData: Int = myTextField.text!.count
        if searchData != 0 {
            searching = true
            for data in dataSource
            {
                if let unitToSearch = myTextField.text
                {
                    let range = data.unitEName.lowercased().range(of: unitToSearch, options: .caseInsensitive, range: nil, locale: nil)
                    if range != nil {
                        self.filteredDataSource.append(data)
                    }
                }
            }
        }else{
            filteredDataSource = dataSource
            searching = false
        }
        selectedButton = myTextField
        addTransparentView(frames: myTextField.frame)
        
        tableViewDropDown.reloadData()
    }

    func addTransparentView(frames: CGRect) {
        let window = UIApplication.shared.keyWindow
        transparentView.frame = window?.frame ?? self.view.frame
        self.view.addSubview(transparentView)
        
        tableViewDropDown.frame = CGRect(x: frames.origin.x, y: frames.origin.y + frames.height, width: frames.width, height: 0)
        self.view.addSubview(tableViewDropDown)
        tableViewDropDown.layer.cornerRadius = 5
        
        transparentView.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        tableViewDropDown.reloadData()
        let tapgesture = UITapGestureRecognizer(target: self, action: #selector(removeTransparentView))
        transparentView.addGestureRecognizer(tapgesture)
        transparentView.alpha = 0
        UIView.animate(withDuration: 0.4, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .curveEaseInOut, animations: {
            self.transparentView.alpha = 0.5
            self.tableViewDropDown.frame = CGRect(x: frames.origin.x, y: frames.origin.y + frames.height + 5, width: frames.width, height: CGFloat(self.filteredDataSource.count * 50))
        }, completion: nil)
    }
    
    @objc func removeTransparentView() {
        let frames = selectedButton.frame
        UIView.animate(withDuration: 0.4, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .curveEaseInOut, animations: {
            self.transparentView.alpha = 0
            self.tableViewDropDown.frame = CGRect(x: frames.origin.x, y: frames.origin.y + frames.height, width: frames.width, height: 0)
        }, completion: nil)
    }

    
    func getUnitNameList(){
        
        let url = URL(string: "https://mis-api.mascoknit.com/api/v1/sem/communication-portal/load-unitname")
        guard let requestUrl = url else { fatalError() }
        
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "GET"
        
        // Set HTTP Request Header
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                
                DispatchQueue.main.async {
                    
                    if let error = error {
                        print("Error took place \(error)")
                        return
                    }
                    guard let data = data else {return}

                    do{
                        let unitNameItemModel = try JSONDecoder().decode(ListUnitNameResponse.self, from: data)
                        self.dataSource = unitNameItemModel._listUnitName
                        
                    }catch let jsonErr{
                        print(jsonErr)
                   }
                }
        }
        task.resume()
    }
    
}

extension ViewController : UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if searching {
            return filteredDataSource.count
        }else{
            return dataSource.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableViewDropDown.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        if searching {
            cell.textLabel?.text = filteredDataSource[indexPath.row].unitEName
        }else{
            cell.textLabel?.text = dataSource[indexPath.row].unitEName
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedButton.text = filteredDataSource[indexPath.row].unitEName
        print("----unitNo-----\(filteredDataSource[indexPath.row].unitNo!)")
        removeTransparentView()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        myTextField.resignFirstResponder()
        return true
    }
    
}


extension ViewController {
  
    struct ListUnitName: Codable {
        var unitNo: Int?
        var unitEName: String = ""
        
        enum CodingKeys: String, CodingKey {
            case unitNo = "unitNo"
            case unitEName = "unitEName"
        }
        
        init(from decoder: Decoder) throws {

               let container = try decoder.container(keyedBy: CodingKeys.self)
               self.unitNo = try container.decodeIfPresent(Int.self, forKey: .unitNo) ?? 0
               self.unitEName = try container.decodeIfPresent(String.self, forKey: .unitEName) ?? ""
           }

           func encode(to encoder: Encoder) throws {

               var container = encoder.container(keyedBy: CodingKeys.self)
               try container.encode(unitNo, forKey: .unitNo)
               try container.encode(unitEName, forKey: .unitEName)
           }
    }
    
    struct ListUnitNameResponse: Codable {
        var error: String = ""
        var _listUnitName : [ListUnitName]

        enum CodingKeys: String, CodingKey {
            case error = "error"
            case _listUnitName
        }
        
         init(from decoder: Decoder) throws {

                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.error = try container.decodeIfPresent(String.self, forKey: .error) ?? ""
                self._listUnitName = try container.decodeIfPresent([ListUnitName].self, forKey: ._listUnitName) ?? []
            }

            func encode(to encoder: Encoder) throws {

                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(error, forKey: .error)
                try container.encode(_listUnitName, forKey: ._listUnitName)
            }
    }
}
