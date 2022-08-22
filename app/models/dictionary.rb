# frozen_string_literal: true

class Dictionary
  attr_reader :requesterTypes, :workBuildings, :workTypes, :studentAssociations, :requestStatuses

  def initialize
    @requesterTypes = { teacher: 'Docente', administrator: 'Administativo', student: 'Estudiante' }
    @studentAssociations = { association: 'Asociación Estudiantil', feucr: 'FEUCR' }
    @workBuildings = { gym: 'Gimnasio', sciencie_labs: 'Laboratiorios Ciencias Generales', cafeteria: 'Comedor',
                       other: 'Otro' }
    @workTypes = { electrical: 'Eléctrico', plumbing: 'Plomería', wood: 'Ebanistería', other: 'Otro' }
    @requestStatuses = { in_process: 'En proceso', completed: 'Completado', closed: 'Cerrado', denied: 'Denegado' }
  end
end
