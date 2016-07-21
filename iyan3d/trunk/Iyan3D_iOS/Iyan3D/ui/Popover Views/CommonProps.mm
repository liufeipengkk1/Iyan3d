//
//  CommonProps.m
//  Iyan3D
//
//  Created by Karthik on 05/07/16.
//  Copyright © 2016 Smackall Games. All rights reserved.
//

#import "CommonProps.h"

@interface CommonProps ()

@end

#define PROP_TABLE 0
#define SUB_PROP_TABLE 1

@implementation CommonProps


- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil WithProps:(std::map < PROP_INDEX, Property >)props
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        sectionHeaders = [[NSMutableArray alloc] init];
        subSectionHeaders = [[NSMutableArray alloc] init];
        selectedListProp.index = UNDEFINED;
        
        std::map< PROP_INDEX, Property >::iterator propIt;
        for(propIt = props.begin(); propIt != props.end(); propIt++) {
            if(propIt->second.type != TYPE_NONE && propIt->second.parentIndex == UNDEFINED) {
                NSString* groupName = [NSString stringWithCString:propIt->second.groupName.c_str() encoding:NSUTF8StringEncoding];
                if(![sectionHeaders containsObject:groupName])
                    [sectionHeaders addObject:groupName];
            }
        }
        
        for( int i = 0; i < [sectionHeaders count]; i++) {
            vector< Property > sectionElements;
            string sectionHeader = [sectionHeaders[i] UTF8String];
            for(propIt = props.begin(); propIt != props.end(); propIt++) {
                if(propIt->second.type != TYPE_NONE && propIt->second.parentIndex == UNDEFINED) {
                    if(propIt->second.groupName == sectionHeader) {
                        sectionElements.push_back(propIt->second);
                    }
                }
            }
            groupedData.insert(pair< string, vector<Property> > (sectionHeader, sectionElements));
        }
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    selectedParentProp.index = UNDEFINED;
    
    NSString* nibName = @"SliderPropCell";
    
    [self.propTableView registerNib:[UINib nibWithNibName:nibName bundle:nil] forCellReuseIdentifier:nibName];
    
    nibName = @"SwitchPropCell";
    
    [self.propTableView registerNib:[UINib nibWithNibName:nibName bundle:nil] forCellReuseIdentifier:nibName];
    
    nibName = @"SegmentCell";
    
    [self.propTableView registerNib:[UINib nibWithNibName:nibName bundle:nil] forCellReuseIdentifier:nibName];
    
    nibName = @"TexturePropCell";
    
    [self.propTableView registerNib:[UINib nibWithNibName:nibName bundle:nil] forCellReuseIdentifier:nibName];

    // Do any additional setup after loading the view.
    [self initializeColorWheel];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self performSelectorInBackground:@selector(applyPhysicsProps) withObject:nil];
}

- (void)initializeColorWheel
{
    UIImage* theImage = [UIImage imageNamed:@"wheel2.png"];
    CGRect frame = CGRectMake(0, 0, self.colorPickerView.frame.size.width, self.colorPickerView.frame.size.height);
    _demoView = [[GetPixelDemo alloc] initWithFrame:frame image:[ANImageBitmapRep imageBitmapRepWithImage:theImage]];
    _demoView.autoresizingMask = self.colorPickerView.autoresizingMask;
    [_demoView addConstraints:self.colorPickerView.constraints];
    _demoView.delegate = self;
    [self.colorPickerView addSubview:_demoView];
    [_demoView setClipsToBounds:YES];
    [self.colorPickerView setClipsToBounds:YES];
}

- (void)pixelDemoGotPixel:(BMPixel)pixel
{
    colorValue = Vector4(pixel.red, pixel.green, pixel.blue, 1.0); //TODO
    [self.selectedColorView setBackgroundColor:[UIColor colorWithRed:pixel.red green:pixel.green blue:pixel.blue alpha:pixel.alpha]];
    [self.delegate changedPropertyAtIndex:selectedParentProp.index WithValue:colorValue AndStatus:NO];
}

- (void)pixelDemoTouchEnded:(BMPixel)pixel
{
    colorValue = Vector4(pixel.red, pixel.green, pixel.blue, 1.0); //TODO
    [self.selectedColorView setBackgroundColor:[UIColor colorWithRed:pixel.red green:pixel.green blue:pixel.blue alpha:pixel.alpha]];
    [self.delegate changedPropertyAtIndex:selectedParentProp.index WithValue:colorValue AndStatus:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if(tableView == self.propTableView)
        return [sectionHeaders count] ? [sectionHeaders count] : 1;
    else
        return [subSectionHeaders count] ? [subSectionHeaders count] : 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(tableView == self.propTableView)
        return (section < [sectionHeaders count]) ? sectionHeaders[section] : @"";
    else
        return (section < [subSectionHeaders count]) ? subSectionHeaders[section] : @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(tableView == self.propTableView)
        return groupedData[[sectionHeaders[section] UTF8String]].size();
    else
        return ([subSectionHeaders count] > 0) ? subGroupedData[[subSectionHeaders[section] UTF8String]].size() : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    vector< Property > tempVec;
    
    if(tableView == self.subPropTable) {
        return [self getCellForCurrentTable:tableView AtIndexPath:indexPath WithTableIndex:SUB_PROP_TABLE];
    } else {
        return [self getCellForCurrentTable:tableView AtIndexPath:indexPath WithTableIndex:PROP_TABLE];
    }
    
}

- (UITableViewCell*) getCellForCurrentTable:(UITableView*) tableView AtIndexPath:(NSIndexPath*) indexPath WithTableIndex:(int) tIndex
{
    std::map< string, vector<Property> > tempMap((tIndex == PROP_TABLE) ? groupedData : subGroupedData);
    NSMutableArray* tempHeaders = (tIndex == PROP_TABLE) ? sectionHeaders : subSectionHeaders;
    if(indexPath.section < (int)tempMap.size()) {
        vector<Property> tempVec = tempMap[[tempHeaders[indexPath.section] UTF8String]];
        
        if((int)indexPath.row < (int)tempVec.size()) {
            Property property = tempVec[indexPath.row];
            
            switch (property.type) {
                case SLIDER_TYPE: {
                    
                    NSString* nibName = @"SliderPropCell";
                    SliderPropCell *cell = (SliderPropCell*)[tableView dequeueReusableCellWithIdentifier:nibName];
                    
                    if (cell == nil) {
                        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:nibName owner:self options:nil];
                        cell = [nib objectAtIndex:0];
                    }
                    
                    cell.delegate = self;
                    cell.indexPath = indexPath;
                    cell.tableIndex = tIndex;
                    cell.title.text =   [NSString stringWithCString:property.title.c_str() encoding:NSUTF8StringEncoding];
                    cell.slider.value =  property.value.x;
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    return cell;
                    
                    break;
                }
                    
                case LIST_TYPE:
                case PARENT_TYPE:
                case BUTTON_TYPE:
                case SWITCH_TYPE: {
                    
                    NSString* nibName = @"SwitchPropCell";
                    SwitchPropCell *cell = (SwitchPropCell*)[tableView dequeueReusableCellWithIdentifier:nibName];
                    
                    if (cell == nil) {
                        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:nibName owner:self options:nil];
                        cell = [nib objectAtIndex:0];
                    }
                    
                    cell.delegate = self;
                    cell.indexPath = indexPath;
                    cell.tableIndex = tIndex;
                    cell.title.text =   [NSString stringWithCString:property.title.c_str() encoding:NSUTF8StringEncoding];
                    [cell.setBtn setHidden:(property.type != BUTTON_TYPE)];
                    [cell.specSwitch setOn:(BOOL)property.value.x];
                    [cell.specSwitch setHidden:(property.type != SWITCH_TYPE)];
                    [cell.nextBtn setHidden:(property.type != PARENT_TYPE)];
                    
                    if(property.type == LIST_TYPE && selectedListProp.index == UNDEFINED && property.value.x == 1)
                        selectedListProp = property;
                    [cell.thumbImgView setHidden:(property.type != LIST_TYPE || property.title != selectedListProp.title)];
                    
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    
                    return cell;
                    break;
                }
                    
                case COLOR_TYPE:
                case IMAGE_TYPE: {
                    NSString* nibName = @"TexturePropCell";
                    TexturePropCell *cell = (TexturePropCell*)[tableView dequeueReusableCellWithIdentifier:nibName];
                    
                    if (cell == nil) {
                        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:nibName owner:self options:nil];
                        cell = [nib objectAtIndex:0];
                    }
                    
                    
                    cell.titleLabel.text =   [NSString stringWithCString:property.title.c_str() encoding:NSUTF8StringEncoding];
                    if(property.type == IMAGE_TYPE && property.fileName.length() > 5) {
                        printf(" \n Texture File Name %s ", property.fileName.c_str());
                        NSString *imageFile = [NSString stringWithCString:property.fileName.c_str() encoding:NSUTF8StringEncoding];
                        cell.texImageView.image = [UIImage imageWithContentsOfFile:imageFile];
                    } else {
                        cell.texImageView.backgroundColor = [UIColor colorWithRed:property.value.x green:property.value.y blue:property.value.z alpha:1.0];
                    }
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    return cell;
                    
                    break;
                }
                    
                case ICON_TYPE: {
                    static NSString *simpleTableIdentifier = @"Cell";
                    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
                    if (cell == nil) {
                        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
                    }
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    cell.imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"Icon%d.png", property.iconId]];
                    cell.textLabel.text = [NSString stringWithCString:property.title.c_str() encoding:NSUTF8StringEncoding];
                    return cell;
                    break;
                }
                    
                case SEGMENT_TYPE: {
                    NSString* nibName = @"SegmentCell";
                    SegmentCell *cell = (SegmentCell*)[tableView dequeueReusableCellWithIdentifier:nibName];
                    
                    if (cell == nil) {
                        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:nibName owner:self options:nil];
                        cell = [nib objectAtIndex:0];
                    }
                    
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    cell.titleLabel.text =   [NSString stringWithCString:property.title.c_str() encoding:NSUTF8StringEncoding];
                    if(property.index != PHYSICS_KIND) {
                        
                    }
                    
                    return cell;
                    break;
                }
                default: {
                    break;
                }
            }
            
            
        }
    }
    
    static NSString *simpleTableIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    return cell;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    int tIndex = (tableView == self.propTableView) ? PROP_TABLE : SUB_PROP_TABLE;
    
    UITableViewCell * cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.backgroundColor = [UIColor whiteColor];
    
    std::map< string, vector<Property> > tempMap = (tIndex == PROP_TABLE) ? groupedData : subGroupedData;
    NSMutableArray* tempHeaders = (tIndex == PROP_TABLE) ? sectionHeaders : subSectionHeaders;
    if(indexPath.section < (int)tempMap.size()) {
        vector<Property> tempVec = tempMap[[tempHeaders[indexPath.section] UTF8String]];
        Property property = tempVec[indexPath.row];
        
        if((int)indexPath.row < (int)tempVec.size()) {
            
            if(property.type == PARENT_TYPE) {
                
                selectedParentProp = property;
                if(property.index == HAS_PHYSICS)
                    physicsProperty = property;
                
                [subSectionHeaders removeAllObjects];
                subGroupedData.clear();
                
                std::map< PROP_INDEX, Property >::iterator propIt;
                for(propIt = selectedParentProp.subProps.begin(); propIt != selectedParentProp.subProps.end(); propIt++) {
                    if(propIt->second.type != TYPE_NONE) {
                        NSString* groupName = [NSString stringWithCString:propIt->second.groupName.c_str() encoding:NSUTF8StringEncoding];
                        if(![subSectionHeaders containsObject:groupName])
                            [subSectionHeaders addObject:groupName];
                    }
                }
                
                for( int i = 0; i < [subSectionHeaders count]; i++) {
                    vector< Property > sectionElements;
                    string sectionHeader = [subSectionHeaders[i] UTF8String];
                    for(propIt = selectedParentProp.subProps.begin(); propIt != selectedParentProp.subProps.end(); propIt++) {
                        if(propIt->second.type != TYPE_NONE) {
                            if(propIt->second.groupName == sectionHeader) {
                                sectionElements.push_back(propIt->second);
                            }
                        }
                    }
                    subGroupedData.insert(pair< string, vector<Property> > (sectionHeader, sectionElements));
                }
                
                
                [self.subPropTable reloadData];
                
                CGRect frame = self.subPropView.frame;
                frame.origin.x = 0;
                [UIView animateWithDuration:0.4 animations:^{
                    [self.subPropView setFrame:frame];
                }];
            } else if(property.type == COLOR_TYPE) {
                selectedParentProp = property;
                CGRect frame = self.colorView.frame;
                frame.origin.x = 0;
                [UIView animateWithDuration:0.4 animations:^{
                    [self.colorView setFrame:frame];
                }];
            } else if(property.type == LIST_TYPE) {
                selectedListProp = property;
                if(property.parentIndex == HAS_PHYSICS)
                    physicsProperty.subProps[PHYSICS_KIND].value = Vector4(property.index);
                    
                [tableView reloadData];
                [self.delegate changedPropertyAtIndex:property.index WithValue:property.value AndStatus:NO];
                [self.delegate changedPropertyAtIndex:property.index WithValue:property.value AndStatus:YES];
            } else if (property.type == ICON_TYPE || property.type == IMAGE_TYPE || property.type == BUTTON_TYPE) {
                [self.delegate changedPropertyAtIndex:property.index WithValue:property.value AndStatus:YES];
                [self.delegate dismissView:self WithProperty:physicsProperty];
            }
        }
        

        
    }
    
}

- (IBAction)backPressed:(id)sender {
    
    CGRect frame = [sender superview].frame;
    frame.origin.x = self.view.frame.size.width;
    [UIView animateWithDuration:0.4 animations:^{
        [[sender superview] setFrame:frame];
    }];
}

- (void) actionMadeInTable:(int) tableIndex AtIndexPath:(NSIndexPath*) indexPath WithValue:(Vector4) value AndStatus:(BOOL) status
{
    Property property;
    
    UITableView* tableView = (tableIndex == PROP_TABLE) ? self.propTableView : self.subPropTable;
    UITableViewCell * cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.backgroundColor = [UIColor whiteColor];
    
    std::map< string, vector<Property> > tempMap = (tableIndex == PROP_TABLE) ? groupedData : subGroupedData;
    NSMutableArray* tempHeaders = (tableIndex == PROP_TABLE) ? sectionHeaders : subSectionHeaders;
    if(indexPath.section < (int)tempMap.size()) {
        vector<Property> tempVec = tempMap[[tempHeaders[indexPath.section] UTF8String]];
        Property property = tempVec[indexPath.row];
        
        if(property.parentIndex == HAS_PHYSICS) {
            physicsProperty.subProps[property.index].value = value;
        }
        
        [self.delegate changedPropertyAtIndex:property.index WithValue:value AndStatus:status];
    }
}

- (void) applyPhysicsProps
{
    [self.delegate applyPhysicsProps:physicsProperty];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end