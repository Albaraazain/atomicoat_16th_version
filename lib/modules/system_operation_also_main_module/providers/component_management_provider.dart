// lib/modules/system_operation_also_main_module/providers/component_management_provider.dart

import 'package:flutter/foundation.dart';
import '../models/system_component.dart';
import '../models/data_point.dart';
import 'base_component_provider.dart';

class ComponentManagementProvider extends BaseComponentProvider {
  Future<void> updateComponentSetValues(
      String componentId, Map<String, double> newSetValues,
      {String? userId}) async {
    await safeUpdateComponent(componentId, () async {
      final component = componentsMap[componentId];
      if (component != null) {
        component.updateSetValues(newSetValues);
        await repository.update(componentId, component, userId: userId);
      }
    });
  }

  Future<void> updateComponentCurrentValues(
      String componentId, Map<String, double> newValues,
      {String? userId}) async {
    await safeUpdateComponent(componentId, () async {
      final component = componentsMap[componentId];
      if (component != null) {
        component.updateCurrentValues(newValues);
        await repository.update(componentId, component, userId: userId);
      }
    });
  }

  Future<void> addParameterDataPoint(
      String componentId, String parameter, DataPoint dataPoint,
      {int maxDataPoints = 1000}) async {
    final component = componentsMap[componentId];
    if (component != null) {
      if (!component.parameterHistory.containsKey(parameter)) {
        component.parameterHistory[parameter] =
            ComponentBuffer<DataPoint>(maxDataPoints);
      }
      component.parameterHistory[parameter]?.add(dataPoint);
      notifyListeners();
    }
  }

  // CRUD Operations
  Future<void> fetchComponents({String? userId}) async {
    try {
      final loadedComponents = await repository.getAll(userId: userId);
      componentsMap.clear();
      for (var component in loadedComponents) {
        componentsMap[component.id] = component;
      }
      notifyListeners();
    } catch (e) {
      print('Error fetching components: $e');
      rethrow;
    }
  }

  Future<void> addComponent(SystemComponent component, {String? userId}) async {
    try {
      await repository.add(component.id, component, userId: userId);
      componentsMap[component.id] = component;
      notifyListeners();
    } catch (e) {
      print('Error adding component: $e');
      rethrow;
    }
  }

  Future<void> removeComponent(String componentId, {String? userId}) async {
    try {
      await repository.delete(componentId, userId: userId);
      componentsMap.remove(componentId);
      notifyListeners();
    } catch (e) {
      print('Error removing component: $e');
      rethrow;
    }
  }

  Future<void> clearAllComponents({String? userId}) async {
    try {
      final componentIds = componentsMap.keys.toList();
      for (var id in componentIds) {
        await repository.delete(id, userId: userId);
      }
      componentsMap.clear();
      notifyListeners();
    } catch (e) {
      print('Error clearing components: $e');
      rethrow;
    }
  }

  // Component Initialization
  void initializeDefaultComponents() {
    _initializeBasicComponents();
    _initializeHeaters();
    _initializeValves();
  }

  void _initializeBasicComponents() {
    addComponent(SystemComponent(
      name: 'Nitrogen Generator',
      description: 'Generates nitrogen gas for the system',
      isActivated: true,
      currentValues: {'flow_rate': 0.0, 'purity': 99.9},
      setValues: {'flow_rate': 50.0, 'purity': 99.9},
      lastCheckDate: DateTime.now().subtract(Duration(days: 30)),
      minValues: {'flow_rate': 10.0, 'purity': 90.0},
      maxValues: {'flow_rate': 100.0, 'purity': 100.0},
    ));

    addComponent(SystemComponent(
      name: 'MFC',
      description: 'Mass Flow Controller for precursor gas',
      isActivated: true,
      currentValues: {
        'flow_rate': 50.0,
        'pressure': 1.0,
        'percent_correction': 0.0,
      },
      setValues: {
        'flow_rate': 50.0,
        'pressure': 1.0,
        'percent_correction': 0.0,
      },
      lastCheckDate: DateTime.now().subtract(Duration(days: 45)),
      minValues: {
        'flow_rate': 0.0,
        'pressure': 0.5,
        'percent_correction': -10.0,
      },
      maxValues: {
        'flow_rate': 100.0,
        'pressure': 2.0,
        'percent_correction': 10.0,
      },
    ));
  }

  void _initializeHeaters() {
    // Add heater components implementation
    final heaterSpecs = [
      {
        'name': 'Precursor Heater 1',
        'minTemp': 20.0,
        'maxTemp': 200.0,
        'defaultTemp': 30.0,
      },
      {
        'name': 'Precursor Heater 2',
        'minTemp': 20.0,
        'maxTemp': 200.0,
        'defaultTemp': 30.0,
      },
      // Add more heaters as needed
    ];

    for (var spec in heaterSpecs) {
      addComponent(SystemComponent(
        name: spec['name'] as String,
        description: 'Temperature control for ${spec['name']}',
        isActivated: true,
        currentValues: {'temperature': spec['defaultTemp'] as double},
        setValues: {'temperature': spec['defaultTemp'] as double},
        lastCheckDate: DateTime.now().subtract(Duration(days: 30)),
        minValues: {'temperature': spec['minTemp'] as double},
        maxValues: {'temperature': spec['maxTemp'] as double},
      ));
    }
  }

  void _initializeValves() {
    // Add valve components implementation
    final valveSpecs = [
      {'name': 'Valve 1', 'type': 'Precursor'},
      {'name': 'Valve 2', 'type': 'Reactant'},
      // Add more valves as needed
    ];

    for (var spec in valveSpecs) {
      addComponent(SystemComponent(
        name: spec['name'] as String,
        description: '${spec['type']} control valve',
        isActivated: true,
        currentValues: {'status': 0.0, 'cycle_count': 0.0},
        setValues: {'status': 0.0},
        lastCheckDate: DateTime.now().subtract(Duration(days: 30)),
        minValues: {'status': 0.0, 'cycle_count': 0.0},
        maxValues: {'status': 1.0, 'cycle_count': 1000000.0},
      ));
    }
  }

  // Component Status Management
  Future<void> activateComponent(String componentId) async {
    await safeUpdateComponent(componentId, () async {
      final component = componentsMap[componentId];
      if (component != null && !component.isActivated) {
        component.isActivated = true;
        await repository.update(componentId, component);
      }
    });
  }

  Future<void> deactivateComponent(String componentId) async {
    await safeUpdateComponent(componentId, () async {
      final component = componentsMap[componentId];
      if (component != null && component.isActivated) {
        component.isActivated = false;
        await repository.update(componentId, component);
      }
    });
  }

  // Error Handling
  Future<void> addErrorMessage(String componentId, String message) async {
    await safeUpdateComponent(componentId, () async {
      final component = componentsMap[componentId];
      if (component != null) {
        component.addErrorMessage(message);
        await repository.update(componentId, component);
      }
    });
  }

  Future<void> clearErrorMessages(String componentId) async {
    await safeUpdateComponent(componentId, () async {
      final component = componentsMap[componentId];
      if (component != null) {
        component.clearErrorMessages();
        await repository.update(componentId, component);
      }
    });
  }
}
