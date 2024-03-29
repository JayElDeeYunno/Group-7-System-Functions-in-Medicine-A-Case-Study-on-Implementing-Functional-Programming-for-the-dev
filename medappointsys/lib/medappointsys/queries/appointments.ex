defmodule Medappointsys.Queries.Appointments do
  import Ecto.Query
  alias MedAppointSys.Repo
  alias Medappointsys.Schemas.Appointment
  alias Medappointsys.Schemas.Doctor
  alias Medappointsys.Schemas.Patient
  #
  def list_appointments do
    Repo.all(from a in Appointment, order_by: [desc: a.updated_at], preload: [:patient, :doctor, :date, :timerange])
  end

  def list_appointments(filter) do
    Repo.all(
      from a in Appointment,
      where: a.status == ^filter,
      order_by: [desc: a.updated_at],
      preload: [:patient, :doctor, :date, :timerange]
    )
  end

  def get_appointment!(id), do: Repo.get!(Appointment, id)

  def create_appointment(attrs \\ %{}) do
    %Appointment{}
    |> Appointment.changeset(attrs)
    |> Repo.insert()
  end

  def update_appointment(%Appointment{} = appointment, attrs) do
    appointment
    |> Appointment.changeset(attrs)
    |> Repo.update()
  end

  def delete_appointment(%Appointment{} = appointment) do
    Repo.delete(appointment)
  end

  def change_appointment(%Appointment{} = appointment, attrs \\ %{}) do
    Appointment.changeset(appointment, attrs)
  end

  def doctor_appointments(doctor_id) do
    Repo.all(
      from a in Appointment,
      where: a.doctor_id == ^doctor_id,
      preload: [:patient, :doctor, :date, :timerange]
    )
  end

  def pending_doctor_appointments(doctor_id) do
    Repo.all(
      from a in Appointment,
      where: a.doctor_id == ^doctor_id and a.status == "Pending",
      preload: [:patient, :doctor, :date, :timerange]
    )
  end

  def confirmed_doctor_appointment(%Appointment{id: appointment_id, doctor_id: doctor_id}, _doctor) do
    appointment = Repo.get(Appointment, appointment_id)

    case appointment do
      %Appointment{status: "pending", doctor_id: ^doctor_id} ->
        appointment
        |> Appointment.changeset(%{status: "Confirmed"})
        |> Repo.update()

      _ ->
        {:error, "Appointment not found or cannot be confirmed"}
    end
  end

  # def completed_doctor_appointment(%Appointment{id: appointment_id}) do
  #   appointment = Repo.get(Appointment, appointment_id)

  #   case appointment do
  #     %Appointment{} = appointment ->
  #       updated_appointment = %Appointment{appointment | status: "Completed"}
  #       Repo.update(updated_appointment)
  #       {:ok, "Appointment completed successfully"}

  #     nil ->
  #       {:error, "Appointment not found"}
  #   end
  # end

  # def canceled_doctor_appointment(%Appointment{id: appointment_id}) do
  #   appointment = Repo.get(Appointment, appointment_id)

  #   case appointment do
  #     %Appointment{} = appointment ->
  #       updated_appointment = %Appointment{appointment | status: "Cancelled"}
  #       Repo.update(updated_appointment)
  #       {:ok, "Appointment cancelled successfully"}

  #     nil ->
  #       {:error, "Appointment not found"}
  #   end
  # end

  # Patient Related (pending, confimed, rescheduled, completed, cancelled)

  def get_patient_appointments(doctor_id, patient_id) do
    Repo.all(
      from a in Appointment,
      where: a.patient_id == ^patient_id and a.doctor_id == ^doctor_id,
      order_by: [desc: a.updated_at],
      preload: [:patient, :doctor, :date, :timerange]
    )
  end

  def get_patient_appointments(patient_id) do
    Repo.all(
      from a in Appointment,
      where: a.patient_id == ^patient_id,
      order_by: [desc: a.updated_at],
      preload: [:patient, :doctor, :date, :timerange]
    )
  end

  def get_doctor_appointments(doctor_id) do
    Repo.all(
      from a in Appointment,
      where: a.doctor_id == ^doctor_id,
      order_by: [desc: a.updated_at],
      preload: [:patient, :doctor, :date, :timerange]
    )
  end

  def filter_patient_appointments(doctor_id, patient_id, filter) do
    Repo.all(
      from a in Appointment,
      where: a.patient_id == ^patient_id and a.doctor_id == ^doctor_id and a.status == ^filter,
      order_by: [desc: a.updated_at],
      preload: [:patient, :doctor, :date, :timerange]
    )
  end

  def filter_patient_appointments(patient_id, filters) do
    Repo.all(
      from a in Appointment,
      where: a.patient_id == ^patient_id and a.status in ^filters,
      order_by: [desc: a.updated_at],
      preload: [:patient, :doctor, :date, :timerange]
    )
  end

  def filter_doctor_appointments(doctor_id, filters) do
    Repo.all(
      from a in Appointment,
      where: a.doctor_id == ^doctor_id and a.status in ^filters,
      order_by: [desc: a.updated_at],
      preload: [:patient, :doctor, :date, :timerange]
    )
  end

  @spec filter_date_appointments(any(), any(), any()) :: any()
  def filter_date_appointments(patient_id, date_id, filters) do
  Repo.all(
    from a in Appointment,
    where: a.patient_id == ^patient_id and a.date_id == ^date_id and a.status in ^filters,
    order_by: [desc: a.updated_at],
    preload: [:patient, :doctor, :date, :timerange]
  )
  end

  def filter_date_doctor_appointments(doctor_id, date_id, filters) do
  Repo.all(
    from a in Appointment,
    where: a.doctor_id == ^doctor_id and a.date_id == ^date_id and a.status in ^filters,
    order_by: [desc: a.updated_at],
    preload: [:patient, :doctor, :date, :timerange]
  )
  end

  @spec confirmed_unique_doctors(any()) :: list()
  def confirmed_unique_doctors(patient_id) do
    Repo.all(
      from a in Appointment,
      join: d in Doctor,
      on: a.doctor_id == d.id,
      distinct: true,
      where: a.patient_id == ^patient_id and a.status == "Confirmed",
      preload: [:doctor]
    ) |> Enum.map(fn %Medappointsys.Schemas.Appointment{doctor: doctor} ->
      doctor
    end)
  end

  def unique_doctors(patient_id) do
    Repo.all(
      from a in Appointment,
      join: d in Doctor,
      on: a.doctor_id == d.id,
      distinct: d.id,
      where: a.patient_id == ^patient_id,
      select: a,
      preload: [:patient, :doctor, :date, :timerange]
    )
  end

  def unique_patients(doctor_id) do
    Repo.all(
      from a in Appointment,
      join: p in Patient,
      on: a.patient_id == p.id,
      distinct: p.id,
      where: a.doctor_id == ^doctor_id,
      select: a,
      preload: [:patient, :doctor, :date, :timerange]
    )
  end

  def request_appointment(%Patient{} = patient, attrs \\ %{}) do
    %Appointment{patient_id: patient.id}
    |> Appointment.changeset(attrs)
    |> Repo.insert()
  end

  # def reschedule_appointment(%Patient{} = patient, %Appointment{id: appointment_id}) do
  #   case get_appointment!(appointment_id) do
  #     %Appointment{status: "Pending"} = appointment ->
  #       new_appointment_attrs = Map.put(appointment, :status, "Rescheduled")
  #       new_appointment = %Appointment{new_appointment_attrs | patient_id: patient.id}
  #       Repo.insert(new_appointment)

  #     _ ->
  #       {:error, "Appointment not found or cannot be rescheduled"}
  #   end
  # end

  # def cancel_appointment(%Patient{} = patient, appointment_id) do
  #   case get_appointment!(appointment_id) do
  #     %Appointment{} = appointment ->
  #       updated_appointment = %Appointment{appointment | status: "Cancelled"}
  #       Repo.update(updated_appointment)
  #       {:ok, "Appointment canceled successfully"}

  #     nil ->
  #       {:error, "Appointment not found"}
  #   end
  # end

  # def doctor_view_patients(%Doctor{id: doctor_id}) do
  #   appointments = doctor_appointments(%Doctor{id: doctor_id})
  #   patient_ids = Enum.map(appointments, &(&1.patient_id))
  #   patients = get_patients!(patient_ids)
  #   patients |> Enum.uniq_by(& &1.id)
  # end

end
