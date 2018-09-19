//
//  PlateNumberInputView.swift
//  VehicleKeyboard
//
//  Created by cjz on 2018/9/19.
//  Copyright © 2018年 Xi'an iRain IoT. Technology Service CO., Ltd. . All rights reserved.
//

import UIKit

@objc(PWPlateNumberInputView)
public class PlateNumberInputView: UIView,
                                    UICollectionViewDelegate,
                                    UICollectionViewDelegateFlowLayout,
                                    UICollectionViewDataSource,
                                    KeyBoardViewDeleagte {
    
    //格子中字体的颜色
    @objc public var textColor = UIColor.black
    //格子中字体的大小
    @objc public var textFontSize:CGFloat = 17
    //设置主题色（会影响格子的边框颜色、按下去时提示栏颜色、确定按钮可用时的颜色）
    @objc public var mainColor = UIColor(red: 65 / 256.0, green: 138 / 256.0, blue: 249 / 256.0, alpha: 1)
    //当前格子中的输入内容
    @objc public  var plateNumber = ""
    
    @objc public weak var  delegate : PlateNumberInputViewDelegate?
    
    let identifier = "PlateInputViewCollectionCell"
    var inputCollectionView :UICollectionView!
    var maxCount = 7
    var selectIndex = 0
    var inputTextfield :UITextField!
    let keyboardView = KeyBoardView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    var selectView = UIView()
    var isSetKeyboard = false//预设值时不设置为第一响应对象
    
    var collectionView :UICollectionView!
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }
    
    private func setupUI() {
        collectionView = UICollectionView(frame: bounds, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: identifier, bundle: Bundle(for: PlateNumberInputView.self)), forCellWithReuseIdentifier: identifier)
        
        translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(collectionView)
        let topCos = NSLayoutConstraint(item: collectionView, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.top, multiplier: 1, constant: 0)
        let leftCos = NSLayoutConstraint(item: collectionView, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.left, multiplier: 1, constant: 0)
        let rightCos = NSLayoutConstraint(item: collectionView, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.right, multiplier: 1, constant: 0)
        let bottomCos = NSLayoutConstraint(item: collectionView, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: 0)
        addConstraints([topCos,leftCos,rightCos,bottomCos])

        inputCollectionView = collectionView
        inputTextfield = UITextField(frame: CGRect(x: 0, y: 0, width: 0, height: frame.height))
        addSubview(inputTextfield)
        
        collectionView.backgroundColor = UIColor.white
        collectionView.isScrollEnabled = false
        
        keyboardView.delegate = self
        keyboardView.mainColor = mainColor
        inputTextfield.inputView = keyboardView
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction(tap:)))
        addGestureRecognizer(tap)
        
        //因为直接切给collectionView加边框 会盖住蓝色的选中边框   所以加一个和collectionView一样大的view再切边框
        setBackgroundView()
        
        //监听键盘
        NotificationCenter.default.addObserver(self, selector: #selector(plateKeyBoardShow), name:NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(plateKeyBoardHidden), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    /*
     检查是否是符合新能源车牌的规则
     **/
    @objc public func checkNewEnginePlate() ->Bool{
        for i in 0..<plateNumber.count {
            let vpl = plateNumber.subString(0, length: i)
            let listModel =  KeyboardEngine.generateLayout(at: i, plateNumber: vpl, numberType:.newEnergy, isMoreType:false);
            var result = false
            for j in 0..<listModel.rowArray().count {
                for k in 0..<listModel.rowArray()[j].count{
                    let key = listModel.rowArray()[j][k]
                    
                    if plateNumber.subString(i, length: 1) == key.text, key.enabled {
                        result = true
                    }
                }
            }
            if !result {
                return false
            }
        }
        return true
    }
    
    
    /*
     检查输入车牌的完整
     **/
    @objc public func isComplete() -> Bool{
        return plateNumber.count == maxCount
    }
    
    @objc public func setPlate(plate:String, type: PlateNumberType){
        plateNumber = plate;
        let isNewEnergy = type == .newEnergy
        var numType = type;
        selectIndex = plate.count == 0 ? 0 : plate.count - 1
        if  numType == .auto, plateNumber.count > 0, plateNumber.subString(0, length: 1) == "W" {
            numType = .wuJing
        } else if numType == .auto,plateNumber.count == 8 {
            numType = .newEnergy
        }
        keyboardView.numType = numType
        isSetKeyboard = true
        changeInputType(isNewEnergy: isNewEnergy)
    }
    
    @objc  public func changeInputType(isNewEnergy: Bool){
        let keyboardView = inputTextfield.inputView as! KeyBoardView
        keyboardView.numType = isNewEnergy ? .newEnergy : .auto
        var numType = keyboardView.numType
        if  plateNumber.count > 0, plateNumber.subString(0, length: 1) == "W" {
            numType = .wuJing
        }
        maxCount = (numType == .newEnergy || numType == .wuJing) ? 8 : 7
        if plateNumber.count > maxCount {
            plateNumber = plateNumber.subString(0, length: plateNumber.count - 1)
        } else if maxCount == 8,plateNumber.count == 7 {
            selectIndex = 7
        }
        if selectIndex > (maxCount - 1) {
            selectIndex = maxCount - 1
        }
        keyboardView.updateText(text: plateNumber, isMoreType: false, inputIndex: selectIndex)
        updateCollection()
    }
    
    private func setBackgroundView(){
        let backgroundView = UIView(frame: inputCollectionView.bounds)
        inputCollectionView.backgroundView = backgroundView
        backgroundView.layer.borderWidth = 1
        backgroundView.layer.borderColor = UIColor(red: 216/255.0, green: 216/255.0, blue: 216/255.0, alpha: 1).cgColor
        backgroundView.isUserInteractionEnabled = false
        backgroundView.layer.masksToBounds = true
        backgroundView.layer.cornerRadius = 2
        selectView.isUserInteractionEnabled = false
        inputCollectionView.addSubview(selectView)
    }
    
    @objc func plateKeyBoardShow(){
        if inputTextfield.isFirstResponder {
            delegate?.plateKeyBoardShow?()
        }
    }
    
    @objc func plateKeyBoardHidden(){
        if inputTextfield.isFirstResponder {
            delegate?.plateKeyBoardHidden?()
        }
    }
    
    @objc func tapAction(tap:UILongPressGestureRecognizer){
        let tapPoint = tap.location(in: self)
        let indexPath = collectionView.indexPathForItem(at: tapPoint)
        collectionView(collectionView, didSelectItemAt: indexPath!)
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectIndex = indexPath.row > plateNumber.count ? plateNumber.count : indexPath.row
        keyboardView.updateText(text: plateNumber, isMoreType: false, inputIndex: selectIndex)
        updateCollection()
    }
    
    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return maxCount
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: (collectionView.frame.size.width / CGFloat(maxCount)) - 0.01, height: collectionView.frame.height)
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! PlateInputViewCollectionCell
        cell.charLabel.text = getPaletChar(index: indexPath.row)
        cell.charLabel.textColor = textColor
        cell.charLabel.font = UIFont.systemFont(ofSize: textFontSize)
        if indexPath.row == selectIndex {
            //给cell加上选中的边框
            selectView.layer.borderWidth = 2
            selectView.layer.borderColor = mainColor.cgColor
            selectView.frame = cell.frame
            let rightSpace :CGFloat = (maxCount - 1) == selectIndex ? 0 : 0.5
            selectView.center = CGPoint(x: cell.center.x + rightSpace, y: cell.center.y)
            corners(view: selectView, index: selectIndex)
        }
        corners(view: cell, index: indexPath.row)
        cell.layer.masksToBounds = true
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    
    func updateCollection(){
        inputCollectionView.reloadData()
        if !inputTextfield.isFirstResponder,!isSetKeyboard {
            inputTextfield.becomeFirstResponder()
        }
        isSetKeyboard = false
    }
    
    func selectComplete(char: String, inputIndex: Int) {
        
        var isMoreType = false
        if char == "删除" , plateNumber.count >= 1 {
            //            KeyboardEngine.subString(str: paletNumber, start: 0, length: paletNumber.count - 1)
            plateNumber = plateNumber.subString(0, length: plateNumber.count - 1)
            selectIndex = plateNumber.count
        }else  if char == "确定"{
            UIApplication.shared.keyWindow?.endEditing(true)
            delegate?.plateInputComplete(plate: plateNumber)
            return
        }else if char == "更多" {
            isMoreType = true
        } else if char == "返回" {
            isMoreType = false
        } else {
            if plateNumber.count <= inputIndex{
                plateNumber += char
            } else {
                let plate = NSMutableString(string: plateNumber)
                plate.replaceCharacters(in: NSRange(location: inputIndex, length: 1), with: char)
                plateNumber = NSString.init(format: "%@", plate) as String
            }
            let keyboardView = inputTextfield.inputView as! KeyBoardView
            let numType = keyboardView.numType == .newEnergy ? PlateNumberType.newEnergy : KeyboardEngine.plateNumberType(with: plateNumber)
            
            maxCount = (numType == .newEnergy || numType == .wuJing) ? 8 : 7
            
            if maxCount > plateNumber.count || selectIndex < plateNumber.count - 1 {
                selectIndex += 1;
            }
        }
        keyboardView.updateText(text: plateNumber, isMoreType: isMoreType, inputIndex: selectIndex)
        updateCollection()
        if (!isMoreType){
            delegate?.palteDidChnage?(plate:plateNumber,complete:plateNumber.count == maxCount)
        }
    }
    
    
    
    func getPaletChar(index:Int) -> String{
        if plateNumber.count > index {
            let NSPalet = plateNumber as NSString
            let char = NSPalet.substring(with: NSRange(location: index, length: 1))
            return char
        }
        return ""
    }
    
    
    
    
    
    func corners(view:UIView, index :Int){
        view.addRounded(cornevrs: UIRectCorner.allCorners, radii: CGSize(width: 0, height: 0))
        if index == 0{
            view.addRounded(cornevrs: UIRectCorner(rawValue: UIRectCorner.RawValue(UInt8(UIRectCorner.topLeft.rawValue) | UInt8(UIRectCorner.bottomLeft.rawValue))), radii: CGSize(width: 2, height: 2))
        } else if index == maxCount - 1 {
            view.addRounded(cornevrs: UIRectCorner(rawValue: UIRectCorner.RawValue(UInt8(UIRectCorner.topRight.rawValue) | UInt8(UIRectCorner.bottomRight.rawValue))), radii: CGSize(width: 2, height: 2))
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
}

